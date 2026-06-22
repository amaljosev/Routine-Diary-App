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
