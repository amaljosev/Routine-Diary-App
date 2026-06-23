// lib/features/backup/presentation/bloc/backup_state.dart
part of 'backup_bloc.dart';

enum BackupStatus { idle, busy, success, failure }

/// Granular phase shown in the progress card.
enum BackupPhase {
  idle,
  uploadingImages, // uploading diary images to Drive
  uploadingEntries, // serialising + uploading the JSON blob
  pruning, // deleting stale backups
  downloading, // restoring: downloading JSON + images from Drive
  writing, // restoring: writing entries to local DB
}

extension BackupPhaseLabel on BackupPhase {
  String get label {
    switch (this) {
      case BackupPhase.idle:
        return '';
      case BackupPhase.uploadingImages:
        return 'Uploading images…';
      case BackupPhase.uploadingEntries:
        return 'Uploading diary entries…';
      case BackupPhase.pruning:
        return 'Cleaning up old backups…';
      case BackupPhase.downloading:
        return 'Downloading backup…';
      case BackupPhase.writing:
        return 'Restoring entries…';
    }
  }
}

class BackupState extends Equatable {
  final BackupStatus status;
  final bool isSignedIn;
  final List<BackupMetadata> backups;
  final BackupMetadata? lastBackup;
  final int? restoredCount;
  final String? message;

  // ── Progress tracking ────────────────────────────────────────────
  final BackupPhase phase;

  /// Images already uploaded (0 when not in uploadingImages phase).
  final int uploadedImages;

  /// Total images to upload (0 when unknown).
  final int totalImages;

  /// Set to true when a backup starts; cleared on success/failure.
  /// Persisted via SharedPreferences so we can detect a crash/kill.
  final bool backupInProgress;

  const BackupState({
    this.status = BackupStatus.idle,
    this.isSignedIn = false,
    this.backups = const [],
    this.lastBackup,
    this.restoredCount,
    this.message,
    this.phase = BackupPhase.idle,
    this.uploadedImages = 0,
    this.totalImages = 0,
    this.backupInProgress = false,
  });

  /// Whether a meaningful progress fraction is available.
  bool get hasImageProgress => totalImages > 0;

  /// 0.0 – 1.0 progress for image phase only; null if not applicable.
  double? get imageProgressFraction =>
      hasImageProgress ? uploadedImages / totalImages : null;

  BackupState copyWith({
    BackupStatus? status,
    bool? isSignedIn,
    List<BackupMetadata>? backups,
    BackupMetadata? lastBackup,
    int? restoredCount,
    String? message,
    BackupPhase? phase,
    int? uploadedImages,
    int? totalImages,
    bool? backupInProgress,
  }) {
    return BackupState(
      status: status ?? this.status,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      backups: backups ?? this.backups,
      lastBackup: lastBackup ?? this.lastBackup,
      restoredCount: restoredCount ?? this.restoredCount,
      message: message,
      phase: phase ?? this.phase,
      uploadedImages: uploadedImages ?? this.uploadedImages,
      totalImages: totalImages ?? this.totalImages,
      backupInProgress: backupInProgress ?? this.backupInProgress,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isSignedIn,
        backups,
        lastBackup,
        restoredCount,
        message,
        phase,
        uploadedImages,
        totalImages,
        backupInProgress,
      ];
}