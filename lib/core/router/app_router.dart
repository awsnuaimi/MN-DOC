import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/editor/presentation/screens/editor_screen.dart';  // أضف

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) {
        // نقرأ معرف الصورة من query parameters
        final imageId = state.uri.queryParameters['id'];
        return EditorScreen();
      },
    ),
  ],
);