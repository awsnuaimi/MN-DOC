import 'package:get_it/get_it.dart';
import '../services/local_db.dart';
import '../../features/settings/data/repositories/profile_repository.dart';
import '../../features/settings/logic/settings_provider.dart';
import '../../features/scanner/data/repositories/scanner_repository.dart';  // <-- أضف
import '../../features/scanner/logic/scanner_provider.dart';                // <-- أضف

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<LocalDB>(() => LocalDB());

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(localDB: sl()),
  );

  sl.registerFactory<SettingsProvider>(
    () => SettingsProvider(profileRepository: sl()),
  );

  // تسجيل تبعيات الماسح
  sl.registerLazySingleton<ScannerRepository>(
    () => ScannerRepository(localDB: sl()),
  );

  sl.registerFactory<ScannerProvider>(
    () => ScannerProvider(repository: sl()),
  );
}