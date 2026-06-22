// lib/features/backup/domain/repositories/backup_repository.dart

import '../../../../core/typedefs/typedefs.dart';
import '../entities/backup_metadata.dart';

/// Contract the data layer (BackupRepositoryImpl) fulfils.
///
/// All methods return [ResultFuture] (= Future<Either<Failure, T>>),
/// so callers never deal with raw exceptions.
abstract class BackupRepository {
  // --- Auth ---

  /// Interactive Google sign-in + Drive appdata authorization.
  ResultFuture<void> signIn();

  /// Silent / lightweight re-auth on app start. Fails with a Failure
  /// if no previously-authorized session can be restored.
ResultFuture<bool> signInSilently();

  /// Sign out and forget the local session.
  ResultFuture<void> signOut();

  // --- Backup ops ---

  /// Reads all local entries, serializes, uploads to appDataFolder,
  /// prunes old backups, returns metadata for the created backup.
  ResultFuture<BackupMetadata> backupEntries();

  /// Lists existing backups, newest first.
  ResultFuture<List<BackupMetadata>> listBackups();

  /// Downloads the backup identified by [driveFileId] and upserts entries
  /// into the local DB (newer-wins, non-destructive). Returns the number
  /// of entries that were applied.
  ResultFuture<int> restoreEntries(String driveFileId);
}