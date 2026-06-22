// lib/features/backup/presentation/bloc/backup_bloc.dart

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/backup/domain/entities/backup_metadata.dart';

import '../../domain/repositories/backup_repository.dart';
part 'backup_event.dart';
part 'backup_state.dart';

/// Mirrors DiaryBloc: takes `repository:` directly, no use cases.
class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final BackupRepository repository;

  BackupBloc({required this.repository}) : super(const BackupState()) {
    on<BackupSignInRequested>(_onSignIn);
    on<BackupSilentSignInRequested>(_onSilentSignIn);
    on<BackupSignOutRequested>(_onSignOut);
    on<BackupNowRequested>(_onBackupNow);
    on<BackupListRequested>(_onListBackups);
    on<BackupRestoreRequested>(_onRestore);
  }

  Future<void> _onSignIn(
    BackupSignInRequested event,
    Emitter<BackupState> emit,
  ) async {
    emit(state.copyWith(status: BackupStatus.busy, message: null));
    final result = await repository.signIn();
    result.fold(
      (f) => emit(
        state.copyWith(
          status: BackupStatus.failure,
          isSignedIn: false,
          message: f.message,
        ),
      ),
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
        ),
      ),
    );
  }

  Future<void> _onBackupNow(
    BackupNowRequested event,
    Emitter<BackupState> emit,
  ) async {
    emit(state.copyWith(status: BackupStatus.busy, message: null));
    final result = await repository.backupEntries();
    result.fold(
      (f) => emit(
        state.copyWith(status: BackupStatus.failure, message: f.message),
      ),
      (meta) => emit(
        state.copyWith(
          status: BackupStatus.success,
          lastBackup: meta,
          message: 'Backed up ${meta.entryCount} entries.',
        ),
      ),
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

  Future<void> _onRestore(
    BackupRestoreRequested event,
    Emitter<BackupState> emit,
  ) async {
    emit(state.copyWith(status: BackupStatus.busy, message: null));
    final result = await repository.restoreEntries(event.driveFileId);
    result.fold(
      (f) => emit(
        state.copyWith(status: BackupStatus.failure, message: f.message),
      ),
      (count) => emit(
        state.copyWith(
          status: BackupStatus.success,
          restoredCount: count,
          message: 'Restored $count entries.',
        ),
      ),
    );
  }
}
