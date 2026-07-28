import 'package:sqflite/sqflite.dart';
import '../../../../core/services/local_db.dart';
import '../models/scanned_image.dart';

class ScannerRepository {
  final LocalDB localDB;

  ScannerRepository({required this.localDB});

  Future<List<ScannedImage>> getAllImages({bool includeDeleted = false}) async {
    final db = await localDB.database;
    String where = includeDeleted ? '' : 'WHERE isDeleted = 0';
    final results = await db.query('scanned_images', where: where, orderBy: 'createdAt DESC');
    return results.map((map) => ScannedImage.fromMap(map)).toList();
  }

  Future<List<ScannedImage>> getFavoriteImages() async {
    final db = await localDB.database;
    final results = await db.query('scanned_images',
        where: 'isFavorite = 1 AND isDeleted = 0', orderBy: 'createdAt DESC');
    return results.map((map) => ScannedImage.fromMap(map)).toList();
  }

  Future<List<ScannedImage>> getDeletedImages() async {
    final db = await localDB.database;
    final results = await db.query('scanned_images',
        where: 'isDeleted = 1', orderBy: 'createdAt DESC');
    return results.map((map) => ScannedImage.fromMap(map)).toList();
  }

  Future<void> saveImage(ScannedImage image) async {
    final db = await localDB.database;
    await db.insert('scanned_images', image.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateImage(ScannedImage image) async {
    final db = await localDB.database;
    await db.update('scanned_images', image.toMap(),
        where: 'id = ?', whereArgs: [image.id]);
  }

  Future<void> renameImage(int id, String newTitle) async {
    final db = await localDB.database;
    await db.update('scanned_images', {'title': newTitle},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await localDB.database;
    await db.update('scanned_images', {'isFavorite': isFavorite ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> softDeleteImage(int id) async {
    final db = await localDB.database;
    await db.update('scanned_images', {'isDeleted': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> restoreImage(int id) async {
    final db = await localDB.database;
    await db.update('scanned_images', {'isDeleted': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteImagePermanently(int id) async {
    final db = await localDB.database;
    await db.delete('scanned_images', where: 'id = ?', whereArgs: [id]);
  }
}