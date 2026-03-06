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
      version: 1,
      onCreate: _onCreate,
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
      updated_at TEXT,
      font_family TEXT
    );
  ''');
  }

  

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }
}