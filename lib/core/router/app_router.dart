import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart'; // أضف
import '../../features/home/presentation/screens/home_screen.dart';
// ... باقي الاستيرادات

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        // ... باقي الفروع
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/scanner',
              builder: (context, state) => const ScannerScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // المحرر يبقى خارج التبويبات
    GoRoute(
      path: '/editor',
      builder: (context, state) => const EditorScreen(),
    ),
  ],
);