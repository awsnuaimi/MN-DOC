import 'package:flutter/foundation.dart';
import '../data/models/profile.dart';
import '../data/repositories/profile_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final ProfileRepository profileRepository;

  SettingsProvider({required this.profileRepository});

  Profile? _profile;
  Profile? get profile => _profile;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();
    _profile = await profileRepository.getProfile();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveProfile(Profile profile) async {
    // إذا كان هناك id سابقاً نحتفظ به
    if (_profile?.id != null) {
      profile = profile.copyWith(id: _profile!.id);
    }
    await profileRepository.saveProfile(profile);
    // إعادة تحميل البروفايل للحصول على id الصحيح وأحدث البيانات
    await loadProfile();
  }
}