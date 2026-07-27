import 'package:go_router/go_router.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

// سنضيف شاشات أخرى لاحقاً
final appRouter = GoRouter(
  initialLocation: '/settings',
  routes: [
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    // مثال لشاشة رئيسية:
    // GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
  ],
);