// lib/features/backup/domain/entities/backup_metadata.dart

import 'package:equatable/equatable.dart';

/// A single backup that lives in the user's Drive appDataFolder.
///
/// Pure domain entity — no Drive/SQFlite types leak in here.
class BackupMetadata extends Equatable {
  /// Drive file id (opaque). Used to download/restore/delete.
  final String driveFileId;

  /// Human-readable file name, e.g. "diary_backup_2026-06-22T06-08-43Z.json".
  final String fileName;

  /// When this backup was created (UTC).
  final DateTime createdAt;

  /// Number of diary entries captured in this backup.
  final int entryCount;

  /// Schema version the backup was written with.
  final int schemaVersion;

  /// Size of the backup blob in bytes (0 if unknown).
  final int sizeBytes;

  const BackupMetadata({
    required this.driveFileId,
    required this.fileName,
    required this.createdAt,
    required this.entryCount,
    required this.schemaVersion,
    this.sizeBytes = 0,
  });

  @override
  List<Object?> get props => [
        driveFileId,
        fileName,
        createdAt,
        entryCount,
        schemaVersion,
        sizeBytes,
      ];
}