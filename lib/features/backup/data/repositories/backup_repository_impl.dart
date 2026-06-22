// lib/features/backup/data/repositories/backup_repository_impl.dart

import 'package:path_provider/path_provider.dart';
import 'package:routine/core/error/exceptions.dart';
import 'package:routine/core/utils/image_path_extractor.dart';

import '../../../../core/error/exception_mapper.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../../../core/utils/backup_serializer.dart';
import '../../domain/entities/backup_metadata.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/diary_local_datasource.dart';
import '../datasources/drive_remote_datasource.dart';
import '../datasources/google_auth_datasource.dart';

/// Single concrete repository, datasources injected by constructor (no DI).
class BackupRepositoryImpl implements BackupRepository {
  final GoogleAuthDataSource authDataSource;
  final DriveRemoteDataSource remoteDataSource;
  final DiaryBackupLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  static const int retentionCount = 5;

  const BackupRepositoryImpl({
    required this.authDataSource,
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  ResultFuture<void> signIn() => guard(() => authDataSource.signIn());

  @override
  ResultFuture<bool> signInSilently() =>
      guard(() => authDataSource.signInSilently());

  @override
  ResultFuture<void> signOut() => guard(() => authDataSource.signOut());

  @override
ResultFuture<BackupMetadata> backupEntries() {
  return guard(() async {
    await _requireConnection();

    final entries = await localDataSource.getAllEntries();

    // ── Upload all images and build path→driveId map ──────────────
    final pathToId = <String, String>{};
    for (final row in entries) {
      final paths = ImagePathExtractor.extractPaths(row);
      for (final path in paths) {
        if (pathToId.containsKey(path)) continue; // deduplicate
        final fileName =
            'img_${path.split('/').last}_${DateTime.now().microsecondsSinceEpoch}';
        try {
          final driveId = await remoteDataSource.uploadImageFile(
            localPath: path,
            fileName: fileName,
          );
          pathToId[path] = driveId;
        } catch (_) {
          // skip unreadable files — entry will restore without that image
        }
      }
    }

    // ── Replace local paths with drive:: placeholders ─────────────
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

    await _pruneOldBackups();
    return manifest.toEntity();
  });
}

  @override
  ResultFuture<List<BackupMetadata>> listBackups() {
    return guard(() async {
      await _requireConnection();
      final manifests = await remoteDataSource.listBackups();
      return manifests.map((m) => m.toEntity()).toList();
    });
  }

  @override
ResultFuture<int> restoreEntries(String driveFileId) {
  return guard(() async {
    await _requireConnection();

    final raw = await remoteDataSource.downloadBackup(driveFileId);
    final parsed = BackupSerializer.deserialize(raw);

    // ── Collect all unique drive IDs across all entries ───────────
    final allDriveIds = <String>{};
    for (final row in parsed.entries) {
      allDriveIds.addAll(ImagePathExtractor.extractDriveIds(row));
    }

    // ── Download each image to local documents directory ──────────
    final docsDir = await getApplicationDocumentsDirectory();
    final idToPath = <String, String>{};

    for (final driveId in allDriveIds) {
      final localPath = '${docsDir.path}/restored_$driveId';
      try {
        await remoteDataSource.downloadImageFile(
          driveFileId: driveId,
          destinationPath: localPath,
        );
        idToPath[driveId] = localPath;
      } catch (_) {
        // skip — broken image placeholder will show instead
      }
    }

    // ── Replace drive:: placeholders with new local paths ─────────
    final restoredEntries = parsed.entries
        .map((row) => ImagePathExtractor.decodePaths(row, idToPath))
        .toList();

    await localDataSource.upsertEntries(restoredEntries);
    return restoredEntries.length;
  });
}

  Future<void> _requireConnection() async {
    final connected = await networkInfo.isConnected;
    if (!connected) {
      throw const NetworkException('No internet connection.');
    }
  }

  /// Best-effort: keep newest [retentionCount] backups, ignore failures.
  Future<void> _pruneOldBackups() async {
    try {
      final manifests = await remoteDataSource.listBackups();
      if (manifests.length <= retentionCount) return;
      final stale = manifests.skip(retentionCount);
      for (final m in stale) {
        try {
          await remoteDataSource.deleteBackup(m.driveFileId);
        } catch (_) {
          /* swallow individual delete errors */
        }
      }
    } catch (_) {
      /* pruning must never fail a successful backup */
    }
  }
}
