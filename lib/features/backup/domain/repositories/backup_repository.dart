// lib/features/backup/domain/repositories/backup_repository.dart

import '../../../../core/typedefs/typedefs.dart';
import '../entities/backup_metadata.dart';

/// Callback fired as a backup progresses.
///
/// [phase]          – which sub-step is running (maps to [BackupPhase] in the
///                    presentation layer via a shared string constant or direct
///                    import — up to the consumer to parse).
/// [uploadedImages] – images uploaded so far (meaningful in image phase).
/// [totalImages]    – total images to upload (0 if no images).
typedef BackupProgressCallback = void Function({
  required String phase,
  required int uploadedImages,
  required int totalImages,
});

abstract class BackupRepository {
  // ── Auth ────────────────────────────────────────────────────────

  ResultFuture<void> signIn();
  ResultFuture<bool> signInSilently();
  ResultFuture<void> signOut();

  // ── Backup ops ──────────────────────────────────────────────────

  /// Backs up all diary entries + images to Drive.
  ///
  /// [onProgress] is called on each meaningful state change so the UI can
  /// show granular feedback without polling.
  ResultFuture<BackupMetadata> backupEntries({
    BackupProgressCallback? onProgress,
  });

  /// Lists existing backups, newest first.
  ResultFuture<List<BackupMetadata>> listBackups();

  /// Restores entries from a Drive backup file.
  ///
  /// [onProgress] is called during download + write phases.
  ResultFuture<int> restoreEntries(
    String driveFileId, {
    BackupProgressCallback? onProgress,
  });

  /// Permanently deletes a backup file from Drive.
  ResultFuture<void> deleteBackup(String driveFileId);
}