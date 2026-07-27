import '../../../../core/services/local_db.dart';
import '../models/profile.dart';

class ProfileRepository {
  final LocalDB localDB;

  ProfileRepository({required this.localDB});

  Future<Profile?> getProfile() async {
    final db = await localDB.database;
    final results = await db.query('profile', limit: 1);
    if (results.isNotEmpty) {
      return Profile.fromMap(results.first);
    }
    return null;
  }

  Future<void> saveProfile(Profile profile) async {
    final db = await localDB.database;
    await db.insert('profile', profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}