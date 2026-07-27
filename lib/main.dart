import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/settings/logic/settings_provider.dart';
import 'features/scanner/logic/scanner_provider.dart';
import 'features/editor/logic/editor_provider.dart';

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
        ChangeNotifierProvider<EditorProvider>(
          create: (_) => EditorProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'MN Doc',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}