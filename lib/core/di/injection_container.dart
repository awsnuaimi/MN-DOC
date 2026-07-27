import 'package:get_it/get_it.dart';
import '../services/local_db.dart';
import '../../features/settings/data/repositories/profile_repository.dart';
import '../../features/settings/logic/settings_provider.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // خدمات
  sl.registerLazySingleton<LocalDB>(() => LocalDB());

  // مستودعات
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(localDB: sl()),
  );

  // Providers (سيتم حقنهم لاحقاً عند الحاجة)
  // حالياً نجهز الـ Factory
  sl.registerFactory<SettingsProvider>(
    () => SettingsProvider(profileRepository: sl()),
  );
}