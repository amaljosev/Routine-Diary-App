import 'dart:developer';

import 'package:routine/core/database/diary_db.dart';
import 'package:sqflite/sqflite.dart';
import '../models/diary_entry_model.dart';

class DiaryLocalDataSource {
  final DiaryDatabase _dbProvider = DiaryDatabase.instance;
  static const table = 'diary_entries';

  Future<void> insertEntry(DiaryEntryModel entry) async {
    try {
      final db = await _dbProvider.database;
      await db.insert(
        table,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      log('insertEntry error: $e', stackTrace: st);
      rethrow; 
    }
  }

  Future<List<DiaryEntryModel>> getAllEntries() async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(table, orderBy: 'created_at DESC');
      return maps.map((m) => DiaryEntryModel.fromMap(m)).toList();
    } catch (e, st) {
      log('getAllEntries error: $e', stackTrace: st);
      return []; 
    }
  }

  Future<DiaryEntryModel?> getEntryById(String id) async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      return DiaryEntryModel.fromMap(maps.first);
    } catch (e, st) {
      log('getEntryById error: $e', stackTrace: st);
      return null;
    }
  }

  Future<int> updateEntry(DiaryEntryModel entry) async {
    try {
      final db = await _dbProvider.database;
      return await db.update(
        table,
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e, st) {
      log('updateEntry error: $e', stackTrace: st);
      return 0; 
    }
  }

  Future<int> deleteEntry(String id) async {
    try {
      final db = await _dbProvider.database;
      return await db.delete(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      log('deleteEntry error: $e', stackTrace: st);
      return 0;
    }
  }

  Future<List<DiaryEntryModel>> search(String query) async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(
        table,
        where: 'title LIKE ? OR content LIKE ? OR preview LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
      );
      return maps.map((m) => DiaryEntryModel.fromMap(m)).toList();
    } catch (e, st) {
      log('search error: $e', stackTrace: st);
      return [];
    }
  }
}
