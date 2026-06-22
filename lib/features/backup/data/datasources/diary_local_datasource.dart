// lib/features/backup/data/datasources/diary_local_datasource.dart

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/diary_db.dart';
import '../../../../core/error/exceptions.dart';

/// Local SQFlite access for diary entries (singleton DB, no DI).
class DiaryBackupLocalDataSource {
  static const String _table = 'diary_entries';
  static const String _idColumn = 'id';
  static const String _updatedAtColumn = 'updated_at';

  Future<Database> get _db async => DiaryDatabase.instance.database;

  Future<List<Map<String, Object?>>> getAllEntries() async {
    try {
      final db = await _db;
      final rows = await db.query(_table);
      return rows.map((r) => Map<String, Object?>.from(r)).toList();
    } catch (e) {
      throw CacheException('Failed to read diary entries: $e');
    }
  }

  Future<int> entryCount() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw CacheException('Failed to count diary entries: $e');
    }
  }

  /// Upserts entries keyed by [id], newer-wins on [updated_at] (TEXT, nullable).
  Future<void> upsertEntries(List<Map<String, Object?>> entries) async {
    if (entries.isEmpty) return;
    try {
      final db = await _db;
      await db.transaction((txn) async {
        for (final incoming in entries) {
          final id = incoming[_idColumn];
          if (id == null) continue;

          final existing = await txn.query(
            _table,
            columns: [_updatedAtColumn],
            where: '$_idColumn = ?',
            whereArgs: [id],
            limit: 1,
          );

          if (existing.isEmpty) {
            await txn.insert(
              _table,
              incoming,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            continue;
          }

          final existingUpdatedAt =
              existing.first[_updatedAtColumn] as String?;
          final incomingUpdatedAt = incoming[_updatedAtColumn] as String?;

          if (_isNewer(incomingUpdatedAt, existingUpdatedAt)) {
            await txn.update(
              _table,
              incoming,
              where: '$_idColumn = ?',
              whereArgs: [id],
            );
          }
        }
      });
    } catch (e) {
      throw CacheException('Failed to upsert diary entries: $e');
    }
  }

  bool _isNewer(String? incoming, String? existing) {
    if (incoming == null) return false;
    if (existing == null) return true;
    final i = DateTime.tryParse(incoming);
    final e = DateTime.tryParse(existing);
    if (i != null && e != null) return i.isAfter(e);
    return incoming.compareTo(existing) > 0;
  }
}