import 'package:sqflite/sqflite.dart';
import '../../../../core/services/local_db.dart';
import '../models/scanned_image.dart';

class ScannerRepository {
  final LocalDB localDB;

  ScannerRepository({required this.localDB});

  Future<List<ScannedImage>> getAllImages() async {
    final db = await localDB.database;
    final results = await db.query('scanned_images', orderBy: 'createdAt DESC');
    return results.map((map) => ScannedImage.fromMap(map)).toList();
  }

  Future<void> saveImage(ScannedImage image) async {
    final db = await localDB.database;
    await db.insert('scanned_images', image.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteImage(int id) async {
    final db = await localDB.database;
    await db.delete('scanned_images', where: 'id = ?', whereArgs: [id]);
  }
}