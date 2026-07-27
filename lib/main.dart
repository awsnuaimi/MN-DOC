import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';               // <-- يجب أن يكون موجودًا
import 'core/router/app_router.dart';
import 'features/settings/logic/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
  ChangeNotifierProvider<SettingsProvider>(
    create: (_) => sl<SettingsProvider>(),
  ),
  ChangeNotifierProvider<ScannerProvider>(
    create: (_) => sl<ScannerProvider>(),
  ),
],
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}