import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/project/project_screen.dart';
import '../../ui/screens/kb/kb_panel.dart';
import '../../ui/screens/recalibration/diff_review_screen.dart';
import '../../ui/screens/settings/settings_screen.dart';

/// GoRouter provider with auth guard redirect
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // Not logged in and not on login page — redirect to login
      if (!isLoggedIn && !isLoggingIn) return '/login';

      // Logged in and on login page — redirect to home
      if (isLoggedIn && isLoggingIn) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) => ProjectScreen(
          projectId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'kb',
            builder: (context, state) => KbPanel(
              projectId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'diff/:diffId',
            builder: (context, state) => DiffReviewScreen(
              projectId: state.pathParameters['id']!,
              diffId: state.pathParameters['diffId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
