// lib/core/database/diary_db.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DiaryDatabase {
  DiaryDatabase._privateConstructor();
  static final DiaryDatabase instance = DiaryDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'routine_diary.db');

    return await openDatabase(
      path,
      version: 2,         
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, 
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diary_entries(
        id                    TEXT PRIMARY KEY,
        title                 TEXT,
        date                  TEXT,
        content               TEXT,
        preview               TEXT,
        mood                  TEXT,
        image_path            TEXT,
        bg_color              TEXT,
        bg_image_path         TEXT,
        bg_gallery_image_path TEXT,
        bg_local_path         TEXT,
        stickers              TEXT,
        images                TEXT,
        created_at            TEXT,
        updated_at            TEXT,
        font_family           TEXT,
        is_favorite           INTEGER NOT NULL DEFAULT 0
      );
    ''');
  }

  // Runs only when an existing install upgrades from an older version.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Safe to run even if the column somehow already exists — 
      // SQLite will just throw which we swallow gracefully.
      try {
        await db.execute(
          'ALTER TABLE diary_entries ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }
}


