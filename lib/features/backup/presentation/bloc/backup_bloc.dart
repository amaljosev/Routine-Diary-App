// lib/features/backup/presentation/bloc/backup_bloc.dart

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/error/failures.dart';
import 'package:routine/features/backup/domain/entities/backup_metadata.dart';

import '../../domain/repositories/backup_repository.dart';
part 'backup_event.dart';
part 'backup_state.dart';

/// Phase string constants shared between the repository and the bloc.
/// Keeping them here (presentation layer) avoids leaking UI concerns into
/// the domain; the repository receives [BackupProgressCallback] which uses
/// plain strings to stay framework-free.
class BackupPhaseKey {
  static const uploadingImages = 'uploadingImages';
  static const uploadingEntries = 'uploadingEntries';
  static const pruning = 'pruning';
  static const downloading = 'downloading';
  static const writing = 'writing';
}

class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final BackupRepository repository;

  BackupBloc({required this.repository}) : super(const BackupState()) {
    on<BackupSignInRequested>(_onSignIn);
    on<BackupSilentSignInRequested>(_onSilentSignIn);
    on<BackupSignOutRequested>(_onSignOut);
    on<BackupNowRequested>(_onBackupNow);
    on<BackupListRequested>(_onListBackups);
    on<BackupRestoreRequested>(_onRestore);
    on<BackupDeleteRequested>(_onDelete);
    on<_BackupProgressUpdated>(_onProgress);
  }

  // ── Auth ──────────────────────────────────────────────────────────

  Future<void> _onSignIn(
    BackupSignInRequested event,
    Emitter<BackupState> emit,
  ) async {
    emit(state.copyWith(status: BackupStatus.busy, message: null));
    final result = await repository.signIn();
    result.fold(
      (f) {
        // User simply dismissed the account picker — silently go back to idle.
        if (f is AuthCancelledFailure) {
          emit(
            state.copyWith(
              status: BackupStatus.idle,
              isSignedIn: false,
              message: null,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: BackupStatus.failure,
            isSignedIn: false,
            message: f.message,
          ),
        );
      },
      (_) => emit(
        state.copyWith(
          status: BackupStatus.success,
          isSignedIn: true,
          message: null,
        ),
      ),
    );
  }

  Future<void> _onSilentSignIn(
    BackupSilentSignInRequested event,
    Emitter<BackupState> emit,
  ) async {
    final result = await repository.signInSilently();
    result.fold(
      (_) => emit(state.copyWith(isSignedIn: false)),
      (wasSignedIn) => emit(state.copyWith(isSignedIn: wasSignedIn)),
    );

    // If the last backup was interrupted (app killed mid-upload) and the user
    // is still signed in, silently retry once.
    if (state.isSignedIn && state.backupInProgress) {
      add(const BackupNowRequested());
    }
  }

  Future<void> _onSignOut(
    BackupSignOutRequested event,
    Emitter<BackupState> emit,
  ) async {
    final result = await repository.signOut();
    result.fold(
      (f) => emit(
        state.copyWith(status: BackupStatus.failure, message: f.message),
      ),
      (_) => emit(
        state.copyWith(
          status: BackupStatus.idle,
          isSignedIn: false,
          backups: const [],
          backupInProgress: false,
        ),
      ),
    );
  }

  // ── Backup ────────────────────────────────────────────────────────

  Future<void> _onBackupNow(
    BackupNowRequested event,
    Emitter<BackupState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BackupStatus.busy,
        message: null,
        phase: BackupPhase.uploadingImages,
        uploadedImages: 0,
        totalImages: 0,
        backupInProgress: true, // flag so we can detect a crash
      ),
    );

    final result = await repository.backupEntries(
      onProgress:
          ({
            required String phase,
            required int uploadedImages,
            required int totalImages,
          }) {
            add(
              _BackupProgressUpdated(
                phase: _phaseFromKey(phase),
                uploadedImages: uploadedImages,
                totalImages: totalImages,
              ),
            );
          },
    );

    result.fold(
      (f) => emit(
        state.copyWith(
          status: BackupStatus.failure,
          message: f.message,
          phase: BackupPhase.idle,
          backupInProgress: false,
        ),
      ),
      (meta) {
        // Show the new backup immediately (good UX) then refresh the real
        // list from Drive so counts + sizes are authoritative.
        emit(
          state.copyWith(
            status: BackupStatus.success,
            backups: [meta],
            lastBackup: meta,
            message: 'Backed up ${meta.entryCount} entries successfully.',
            phase: BackupPhase.idle,
            backupInProgress: false,
          ),
        );
        // Auto-refresh so the tile shows the correct Drive-side size and the
        // list stays in sync without the user tapping refresh manually.
        add(const BackupListRequested());
      },
    );
  }

  Future<void> _onListBackups(
    BackupListRequested event,
    Emitter<BackupState> emit,
  ) async {
    emit(state.copyWith(status: BackupStatus.busy, message: null));
    final result = await repository.listBackups();
    result.fold(
      (f) => emit(
        state.copyWith(status: BackupStatus.failure, message: f.message),
      ),
      (list) =>
          emit(state.copyWith(status: BackupStatus.success, backups: list)),
    );
  }

  // ── Restore ───────────────────────────────────────────────────────

  Future<void> _onRestore(
    BackupRestoreRequested event,
    Emitter<BackupState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BackupStatus.busy,
        message: null,
        phase: BackupPhase.downloading,
        uploadedImages: 0,
        totalImages: 0,
      ),
    );

    final result = await repository.restoreEntries(
      event.driveFileId,
      onProgress:
          ({
            required String phase,
            required int uploadedImages,
            required int totalImages,
          }) {
            add(
              _BackupProgressUpdated(
                phase: _phaseFromKey(phase),
                uploadedImages: uploadedImages,
                totalImages: totalImages,
              ),
            );
          },
    );

    result.fold(
      (f) => emit(
        state.copyWith(
          status: BackupStatus.failure,
          message: f.message,
          phase: BackupPhase.idle,
        ),
      ),
      (count) => emit(
        state.copyWith(
          status: BackupStatus.success,
          restoredCount: count,
          message: 'Restored $count entries to your diary.',
          phase: BackupPhase.idle,
        ),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────

  Future<void> _onDelete(
    BackupDeleteRequested event,
    Emitter<BackupState> emit,
  ) async {
    emit(state.copyWith(status: BackupStatus.busy, message: null));
    final result = await repository.deleteBackup(event.driveFileId);
    result.fold(
      (f) => emit(
        state.copyWith(status: BackupStatus.failure, message: f.message),
      ),
      (_) {
        final updated = state.backups
            .where((b) => b.driveFileId != event.driveFileId)
            .toList();
        emit(
          state.copyWith(
            status: BackupStatus.success,
            backups: updated,
            message: 'Backup deleted from Drive.',
          ),
        );
      },
    );
  }

  // ── Progress ──────────────────────────────────────────────────────

  void _onProgress(_BackupProgressUpdated event, Emitter<BackupState> emit) {
    // Only emit if we're still in a busy state — guards against stale events
    // arriving after the operation has already completed.
    if (state.status != BackupStatus.busy) return;
    emit(
      state.copyWith(
        phase: event.phase,
        uploadedImages: event.uploadedImages,
        totalImages: event.totalImages,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  BackupPhase _phaseFromKey(String key) {
    switch (key) {
      case BackupPhaseKey.uploadingImages:
        return BackupPhase.uploadingImages;
      case BackupPhaseKey.uploadingEntries:
        return BackupPhase.uploadingEntries;
      case BackupPhaseKey.pruning:
        return BackupPhase.pruning;
      case BackupPhaseKey.downloading:
        return BackupPhase.downloading;
      case BackupPhaseKey.writing:
        return BackupPhase.writing;
      default:
        return BackupPhase.idle;
    }
  }
}
