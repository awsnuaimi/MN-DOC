import 'package:flutter_test/flutter_test.dart';
import 'package:mn_doc/features/settings/data/models/profile.dart';
import 'package:mn_doc/features/settings/data/repositories/profile_repository.dart';
import 'package:mn_doc/features/settings/logic/settings_provider.dart';
import 'package:mn_doc/core/services/local_db.dart';

/// مستودع وهمي يحاكي جدول profile الحقيقي، بما فيه سلوك autoincrement.
class FakeProfileRepository extends ProfileRepository {
  final List<Profile> _rows = [];
  int _nextId = 1;

  FakeProfileRepository() : super(localDB: LocalDB());

  @override
  Future<Profile?> getProfile() async {
    if (_rows.isEmpty) return null;
    // نفس منطق ORDER BY id DESC LIMIT 1
    final sorted = List<Profile>.from(_rows)..sort((a, b) => b.id!.compareTo(a.id!));
    return sorted.first;
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    if (profile.id != null) {
      final i = _rows.indexWhere((r) => r.id == profile.id);
      if (i != -1) {
        _rows[i] = profile;
        return;
      }
    }
    if (_rows.isNotEmpty) {
      // تحديث أول سطر موجود بدل إنشاء سطر جديد
      _rows[0] = profile.copyWith(id: _rows[0].id);
      return;
    }
    _rows.add(profile.copyWith(id: _nextId++));
  }

  int get rowCount => _rows.length;
}

void main() {
  late FakeProfileRepository repo;
  late SettingsProvider provider;

  setUp(() {
    repo = FakeProfileRepository();
    provider = SettingsProvider(profileRepository: repo);
  });

  test(
      'باج سابق: حفظ البروفايل عدة مرات يجب أن يحدّث نفس السطر، لا ينشئ سطوراً مكررة',
      () async {
    await provider.saveProfile(Profile(name: 'أحمد', email: 'a@test.com', phone: '111'));
    await provider.saveProfile(Profile(name: 'أحمد علي', email: 'a@test.com', phone: '222'));
    await provider.saveProfile(Profile(name: 'أحمد علي محمد', email: 'a@test.com', phone: '333'));

    expect(repo.rowCount, 1, reason: 'يجب أن يبقى سطر واحد فقط بعد 3 عمليات حفظ');

    await provider.loadProfile();
    expect(provider.profile?.name, 'أحمد علي محمد', reason: 'يجب أن تُقرأ آخر قيمة محفوظة');
  });

  test('تحميل بروفايل غير موجود يرجّع null بدون كراش', () async {
    await provider.loadProfile();
    expect(provider.profile, isNull);
  });
}