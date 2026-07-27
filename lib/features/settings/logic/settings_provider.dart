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
    await profileRepository.saveProfile(profile);
    _profile = profile;
    notifyListeners();
  }
}