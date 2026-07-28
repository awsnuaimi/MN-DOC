import '../../../../core/services/local_db.dart';
import '../models/profile.dart';

class ProfileRepository {
  final LocalDB localDB;

  ProfileRepository({required this.localDB});

  Future<Profile?> getProfile() async {
    final db = await localDB.database;
    final results = await db.query('profile', orderBy: 'id DESC', limit: 1);
    if (results.isNotEmpty) {
      return Profile.fromMap(results.first);
    }
    return null;
  }

  Future<void> saveProfile(Profile profile) async {
    final db = await localDB.database;
    if (profile.id != null) {
      await db.update('profile', profile.toMap(),
          where: 'id = ?', whereArgs: [profile.id]);
    } else {
      final existing = await db.query('profile', limit: 1);
      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as int;
        final map = profile.toMap();
        map['id'] = existingId;
        await db.update('profile', map, where: 'id = ?', whereArgs: [existingId]);
      } else {
        await db.insert('profile', profile.toMap());
      }
    }
  }
}