// lib/core/utils/backup_serializer.dart

import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../error/exceptions.dart';
import '../error/exception_mapper.dart';
import '../error/failures.dart';
import '../typedefs/typedefs.dart';

/// Current backup schema version. Bump when the on-disk format changes.
const int kCurrentBackupSchemaVersion = 1;

/// Result of parsing a backup blob.
class ParsedBackup {
  final int schemaVersion;
  final DateTime createdAt;
  final List<DataMap> entries;

  const ParsedBackup({
    required this.schemaVersion,
    required this.createdAt,
    required this.entries,
  });

  int get entryCount => entries.length;
}

/// Serializes/deserializes diary entries to/from a versioned JSON envelope.
class BackupSerializer {
  /// entries -> versioned JSON string.
  static String serialize(List<DataMap> entries) {
    final envelope = <String, Object?>{
      'schemaVersion': kCurrentBackupSchemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'entryCount': entries.length,
      'entries': entries,
    };
    return jsonEncode(envelope);
  }

  /// Throwing deserialize. Throws [BackupFormatException] on any problem.
  static ParsedBackup deserialize(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const BackupFormatException('Backup is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException('Backup root is not an object.');
    }

    final version = decoded['schemaVersion'];
    if (version is! int) {
      throw const BackupFormatException('Backup is missing a schema version.');
    }
    if (version > kCurrentBackupSchemaVersion) {
      throw BackupFormatException(
        'Backup was created by a newer app version ($version). '
        'Please update the app.',
      );
    }

    final rawEntries = decoded['entries'];
    if (rawEntries is! List) {
      throw const BackupFormatException('Backup has no entries list.');
    }

    final entries = <DataMap>[];
    for (final e in rawEntries) {
      if (e is! Map) {
        throw const BackupFormatException('A backup entry is malformed.');
      }
      entries.add(e.map((k, v) => MapEntry('$k', v as Object?)));
    }

    final migrated = _migrate(entries, fromVersion: version);

    final createdAt =
        DateTime.tryParse('${decoded['createdAt']}')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return ParsedBackup(
      schemaVersion: kCurrentBackupSchemaVersion,
      createdAt: createdAt,
      entries: migrated,
    );
  }

  /// fpdart-friendly variant: never throws, returns Either.
  static Either<Failure, ParsedBackup> deserializeEither(String raw) =>
      guardSync(() => deserialize(raw));

  /// Forward-migrates entries written by older schema versions.
  static List<DataMap> _migrate(List<DataMap> entries,
      {required int fromVersion}) {
    var current = entries;
    var v = fromVersion;

    // v0/v1 -> ensure is_favorite exists (added in DB v2).
    if (v < 1) {
      current = current.map((e) {
        final copy = Map<String, Object?>.from(e);
        copy.putIfAbsent('is_favorite', () => 0);
        return copy;
      }).toList();
      v = 1;
    }

    // Future migrations: if (v < 2) { ... v = 2; }
    return current;
  }
}