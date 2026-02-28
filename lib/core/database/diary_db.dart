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
      version: 3, // Current version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE diary_entries(
      id TEXT PRIMARY KEY,
      title TEXT,
      date TEXT,               
      content TEXT,
      preview TEXT,
      mood TEXT,
      image_path TEXT,
      bg_color TEXT,
      bg_image_path TEXT,
      bg_gallery_image_path TEXT,
      bg_local_path TEXT,
      stickers TEXT,
      images TEXT,
      created_at TEXT,          
      updated_at TEXT          
    );
  ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Helper to check if a column exists
    Future<bool> columnExists(String columnName) async {
      final result = await db.rawQuery(
        "PRAGMA table_info(diary_entries);",
      );
      return result.any((col) => col['name'] == columnName);
    }

    // Upgrade to version 2: add bg_gallery_image_path
    if (oldVersion < 2) {
      final exists = await columnExists('bg_gallery_image_path');
      if (!exists) {
        await db.execute('ALTER TABLE diary_entries ADD COLUMN bg_gallery_image_path TEXT;');
      }
    }

    // Upgrade to version 3: add bg_local_path
    if (oldVersion < 3) {
      final exists = await columnExists('bg_local_path');
      if (!exists) {
        await db.execute('ALTER TABLE diary_entries ADD COLUMN bg_local_path TEXT;');
      }
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }
}