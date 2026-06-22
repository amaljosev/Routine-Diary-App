// lib/features/backup/presentation/bloc/backup_state.dart
part of 'backup_bloc.dart';

enum BackupStatus { idle, busy, success, failure }

class BackupState extends Equatable {
  final BackupStatus status;
  final bool isSignedIn;
  final List<BackupMetadata> backups;
  final BackupMetadata? lastBackup;
  final int? restoredCount;
  final String? message; // user-facing (Failure.message or success text)

  const BackupState({
    this.status = BackupStatus.idle,
    this.isSignedIn = false,
    this.backups = const [],
    this.lastBackup,
    this.restoredCount,
    this.message,
  });

  BackupState copyWith({
    BackupStatus? status,
    bool? isSignedIn,
    List<BackupMetadata>? backups,
    BackupMetadata? lastBackup,
    int? restoredCount,
    String? message,
  }) {
    return BackupState(
      status: status ?? this.status,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      backups: backups ?? this.backups,
      lastBackup: lastBackup ?? this.lastBackup,
      restoredCount: restoredCount ?? this.restoredCount,
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [status, isSignedIn, backups, lastBackup, restoredCount, message];
}