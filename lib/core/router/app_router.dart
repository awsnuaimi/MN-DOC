import 'package:go_router/go_router.dart';
import '../widgets/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/editor/presentation/screens/editor_screen.dart';
import '../../features/templates/presentation/screens/templates_screen.dart';
import '../../features/pdf_form/presentation/screens/pdf_form_screen.dart';
import '../widgets/app_shell.dart';

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
              path: '/templates',
              builder: (context, state) => const TemplatesScreen(),
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
    // الماسح يُفتح عبر زر FAB بالشريط السفلي (push) وليس تبويباً دائماً
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) {
        final imageId = state.extra as String?;
        return EditorScreen(imageId: imageId);
      },
    ),
    GoRoute(
      path: '/pdf-form',
      builder: (context, state) => PdfFormScreen(pdfPath: state.extra as String),
    ),
  ],
);