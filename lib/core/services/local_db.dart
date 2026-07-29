import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mn_doc.db');
    return openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        phone TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE scanned_images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filePath TEXT,
        title TEXT,
        createdAt TEXT,
        isFavorite INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0,
        isPinned INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE scanned_images ADD COLUMN isFavorite INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE scanned_images ADD COLUMN isDeleted INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE scanned_images ADD COLUMN isPinned INTEGER DEFAULT 0');
    }
  }
}