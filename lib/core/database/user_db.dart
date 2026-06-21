// lib/core/database/user_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserDatabase {
  UserDatabase._privateConstructor();
  static final UserDatabase instance = UserDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'user.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
  CREATE TABLE user_analytics (
    userId TEXT PRIMARY KEY,
    username TEXT,
    avatar TEXT,
    installedDate TEXT,
    lastLogin TEXT,
    lastCompleted TEXT,
    bestStreak INTEGER DEFAULT 0,
    currentStreak INTEGER DEFAULT 0,
    totalDaysActive INTEGER DEFAULT 0,
    achievements TEXT,
    stars INTEGER DEFAULT 0
  );
''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE user_analytics ADD COLUMN newField TEXT;');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }
}
