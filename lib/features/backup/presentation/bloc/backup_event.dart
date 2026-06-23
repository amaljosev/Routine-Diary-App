// lib/features/backup/presentation/bloc/backup_event.dart
part of 'backup_bloc.dart';

abstract class BackupEvent extends Equatable {
  const BackupEvent();
  @override
  List<Object?> get props => [];
}

class BackupSignInRequested extends BackupEvent {
  const BackupSignInRequested();
}

class BackupSilentSignInRequested extends BackupEvent {
  const BackupSilentSignInRequested();
}

class BackupSignOutRequested extends BackupEvent {
  const BackupSignOutRequested();
}

class BackupNowRequested extends BackupEvent {
  const BackupNowRequested();
}

class BackupListRequested extends BackupEvent {
  const BackupListRequested();
}

class BackupRestoreRequested extends BackupEvent {
  final String driveFileId;
  const BackupRestoreRequested(this.driveFileId);
  @override
  List<Object?> get props => [driveFileId];
}

class BackupDeleteRequested extends BackupEvent {
  final String driveFileId;
  const BackupDeleteRequested(this.driveFileId);
  @override
  List<Object?> get props => [driveFileId];
}

/// Fired internally by the bloc when the repository reports progress.
class _BackupProgressUpdated extends BackupEvent {
  final BackupPhase phase;
  final int uploadedImages;
  final int totalImages;

  const _BackupProgressUpdated({
    required this.phase,
    required this.uploadedImages,
    required this.totalImages,
  });

  @override
  List<Object?> get props => [phase, uploadedImages, totalImages];
}