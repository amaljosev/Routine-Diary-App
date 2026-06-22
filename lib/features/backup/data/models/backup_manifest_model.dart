// lib/features/backup/data/models/backup_manifest_model.dart

import 'package:googleapis/drive/v3.dart' as drive;

import '../../domain/entities/backup_metadata.dart';

/// Maps a Drive file's metadata <-> appProperties <-> domain entity.
class BackupManifestModel {
  final String driveFileId;
  final String fileName;
  final DateTime createdAt;
  final int entryCount;
  final int schemaVersion;
  final int sizeBytes;

  const BackupManifestModel({
    required this.driveFileId,
    required this.fileName,
    required this.createdAt,
    required this.entryCount,
    required this.schemaVersion,
    required this.sizeBytes,
  });

  factory BackupManifestModel.fromDriveFile(drive.File file) {
    final props = file.appProperties ?? const {};
    return BackupManifestModel(
      driveFileId: file.id ?? '',
      fileName: file.name ?? 'unknown.json',
      createdAt: DateTime.tryParse(props['createdAt'] ?? '')?.toUtc() ??
          file.createdTime?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      entryCount: int.tryParse(props['entryCount'] ?? '') ?? 0,
      schemaVersion: int.tryParse(props['schemaVersion'] ?? '') ?? 1,
      sizeBytes: int.tryParse(file.size ?? '') ?? 0,
    );
  }

  Map<String, String> toAppProperties() => {
        'createdAt': createdAt.toUtc().toIso8601String(),
        'entryCount': '$entryCount',
        'schemaVersion': '$schemaVersion',
      };

  BackupMetadata toEntity() => BackupMetadata(
        driveFileId: driveFileId,
        fileName: fileName,
        createdAt: createdAt,
        entryCount: entryCount,
        schemaVersion: schemaVersion,
        sizeBytes: sizeBytes,
      );
}