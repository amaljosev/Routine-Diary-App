// lib/features/backup/data/repositories/backup_repository_impl.dart

import 'package:path_provider/path_provider.dart';
import 'package:routine/core/error/exceptions.dart';
import 'package:routine/core/utils/image_path_extractor.dart';
import 'package:routine/features/backup/presentation/bloc/backup_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exception_mapper.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../../../core/utils/backup_serializer.dart';
import '../../domain/entities/backup_metadata.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/diary_local_datasource.dart';
import '../datasources/drive_remote_datasource.dart';
import '../datasources/google_auth_datasource.dart';

/// SharedPreferences key that flags an in-progress backup.
/// Written before the upload starts; cleared on success.
/// If the app is killed mid-upload this flag stays set and the BLoC
/// detects it on the next silent sign-in → automatic silent retry.
const _kBackupInProgressKey = 'backup_in_progress';

class BackupRepositoryImpl implements BackupRepository {
  final GoogleAuthDataSource authDataSource;
  final DriveRemoteDataSource remoteDataSource;
  final DiaryBackupLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const BackupRepositoryImpl({
    required this.authDataSource,
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ── Auth ──────────────────────────────────────────────────────────

  @override
  ResultFuture<void> signIn() => guard(() => authDataSource.signIn());

  @override
  ResultFuture<bool> signInSilently() =>
      guard(() => authDataSource.signInSilently());

  @override
  ResultFuture<void> signOut() => guard(() => authDataSource.signOut());

  // ── Backup ────────────────────────────────────────────────────────

  @override
  ResultFuture<BackupMetadata> backupEntries({
    BackupProgressCallback? onProgress,
  }) {
    return guard(() async {
      await _requireConnection();

      // Mark as in-progress so a crash/kill is detectable on next open.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kBackupInProgressKey, true);

      try {
        // ── Step 1: wipe Drive clean ───────────────────────────────
        //
        // Every backup is a complete snapshot of ALL diary entries and images,
        // so there is never a reason to keep more than one copy.
        // We delete everything *before* uploading so Drive never holds two
        // full copies simultaneously and Drive storage stays minimal.
        await _deleteAllDriveFiles();

        // ── Step 2: read diary entries ─────────────────────────────
        final entries = await localDataSource.getAllEntries();

        // ── Step 3: collect + deduplicate image paths ──────────────
        final allPaths = <String>{};
        for (final row in entries) {
          allPaths.addAll(ImagePathExtractor.extractPaths(row));
        }
        final pathList = allPaths.toList();
        final totalImages = pathList.length;

        // ── Step 4: upload images, one by one with progress ────────
        onProgress?.call(
          phase: BackupPhaseKey.uploadingImages,
          uploadedImages: 0,
          totalImages: totalImages,
        );

        final pathToId = <String, String>{};
        for (int i = 0; i < pathList.length; i++) {
          final path = pathList[i];
          final fileName =
              'img_${path.split('/').last}_${DateTime.now().microsecondsSinceEpoch}';
          try {
            final driveId = await remoteDataSource.uploadImageFile(
              localPath: path,
              fileName: fileName,
            );
            pathToId[path] = driveId;
          } catch (_) {
            // Unreadable / missing file — the entry will restore without
            // that image rather than failing the entire backup.
          }
          onProgress?.call(
            phase: BackupPhaseKey.uploadingImages,
            uploadedImages: i + 1,
            totalImages: totalImages,
          );
        }

        // ── Step 5: encode entries + upload JSON ───────────────────
        onProgress?.call(
          phase: BackupPhaseKey.uploadingEntries,
          uploadedImages: totalImages,
          totalImages: totalImages,
        );

        final encodedEntries = entries
            .map((row) => ImagePathExtractor.encodePaths(row, pathToId))
            .toList();

        final json = BackupSerializer.serialize(encodedEntries);
        final now = DateTime.now().toUtc();
        final stamp = now.toIso8601String().replaceAll(':', '-');
        final fileName = 'diary_backup_$stamp.json';

        final manifest = await remoteDataSource.uploadBackup(
          fileName: fileName,
          jsonContent: json,
          appProperties: {
            'createdAt': now.toIso8601String(),
            'entryCount': '${entries.length}',
            'schemaVersion': '$kCurrentBackupSchemaVersion',
          },
        );

        // ── Step 6: clear the interrupt flag ───────────────────────
        await prefs.setBool(_kBackupInProgressKey, false);

        return manifest.toEntity();
      } catch (_) {
        // Leave the flag set — the next open will detect and retry.
        rethrow;
      }
    });
  }

  // ── List ──────────────────────────────────────────────────────────

  @override
  ResultFuture<List<BackupMetadata>> listBackups() {
    return guard(() async {
      await _requireConnection();
      // listBackups() in the datasource already filters to diary_backup_*.json
      // files only, so image files never appear in the returned list.
      final manifests = await remoteDataSource.listBackups();
      return manifests.map((m) => m.toEntity()).toList();
    });
  }

  // ── Restore ───────────────────────────────────────────────────────

  @override
  ResultFuture<int> restoreEntries(
    String driveFileId, {
    BackupProgressCallback? onProgress,
  }) {
    return guard(() async {
      await _requireConnection();

      // ── Download JSON manifest ─────────────────────────────────
      onProgress?.call(
        phase: BackupPhaseKey.downloading,
        uploadedImages: 0,
        totalImages: 0,
      );

      final raw = await remoteDataSource.downloadBackup(driveFileId);
      final parsed = BackupSerializer.deserialize(raw);

      // ── Collect unique image Drive IDs ─────────────────────────
      final allDriveIds = <String>{};
      for (final row in parsed.entries) {
        allDriveIds.addAll(ImagePathExtractor.extractDriveIds(row));
      }
      final driveIdList = allDriveIds.toList();
      final totalImages = driveIdList.length;

      // ── Download each image ────────────────────────────────────
      final docsDir = await getApplicationDocumentsDirectory();
      final idToPath = <String, String>{};

      for (int i = 0; i < driveIdList.length; i++) {
        final driveId = driveIdList[i];
        final localPath = '${docsDir.path}/restored_$driveId';
        try {
          await remoteDataSource.downloadImageFile(
            driveFileId: driveId,
            destinationPath: localPath,
          );
          idToPath[driveId] = localPath;
        } catch (_) {
          // Broken image — a placeholder is shown instead.
        }
        onProgress?.call(
          phase: BackupPhaseKey.downloading,
          uploadedImages: i + 1,
          totalImages: totalImages,
        );
      }

      // ── Write entries to local DB ──────────────────────────────
      onProgress?.call(
        phase: BackupPhaseKey.writing,
        uploadedImages: totalImages,
        totalImages: totalImages,
      );

      final restoredEntries = parsed.entries
          .map((row) => ImagePathExtractor.decodePaths(row, idToPath))
          .toList();

      await localDataSource.upsertEntries(restoredEntries);
      return restoredEntries.length;
    });
  }

  // ── Delete single backup ──────────────────────────────────────────

  /// Deletes the JSON manifest for one backup from Drive.
  /// Note: companion image files from that backup are left in place because
  /// since we only ever keep one full backup at a time, calling
  /// [backupEntries] always wipes everything first anyway.
  /// If the user explicitly deletes the one backup, use [_deleteAllDriveFiles]
  /// to wipe images too.
  @override
  ResultFuture<void> deleteBackup(String driveFileId) {
    return guard(() async {
      await _requireConnection();
      // Delete the JSON manifest.
      await remoteDataSource.deleteFile(driveFileId);
      // Also wipe any orphaned image files so Drive storage stays clean.
      await _deleteAllDriveFiles(exceptId: driveFileId);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Future<void> _requireConnection() async {
    final connected = await networkInfo.isConnected;
    if (!connected) throw const NetworkException('No internet connection.');
  }

  /// Deletes every file in appDataFolder.
  /// Pass [exceptId] to skip one file (e.g. the manifest we already deleted).
  /// Individual delete failures are swallowed so one orphaned file never
  /// blocks a fresh backup.
  Future<void> _deleteAllDriveFiles({String? exceptId}) async {
    try {
      final allFiles = await remoteDataSource.listAllFiles();
      for (final file in allFiles) {
        final id = file.id;
        if (id == null || id == exceptId) continue;
        try {
          await remoteDataSource.deleteFile(id);
        } catch (_) {
          // Swallow — orphaned files don't block the new backup.
        }
      }
    } catch (_) {
      // If the listing itself fails, proceed anyway (upload is more important).
    }
  }
}

/// Expose the SharedPreferences flag so your DI / main can seed the
/// initial [BackupState.backupInProgress] field before creating the BLoC.
Future<bool> wasBackupInterrupted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kBackupInProgressKey) ?? false;
}