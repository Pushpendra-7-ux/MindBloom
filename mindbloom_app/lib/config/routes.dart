import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/category/category_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/checkin/checkin_screen.dart';
import '../screens/recommendations/recommendations_screen.dart';
import '../screens/meditation/meditation_screen.dart';
import '../screens/breathing/breathing_screen.dart';
import '../screens/nearby/nearby_screen.dart';
import '../screens/tracker/tracker_screen.dart';
import '../screens/mood_history/mood_history_screen.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../widgets/app_shell.dart';

// Listenable that notifies when auth state changes
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifierListenable(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.token != null;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/signup' ||
                          state.matchedLocation == '/';
      final isCategoryRoute = state.matchedLocation == '/category';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      // Allow category route for logged in users
      if (isLoggedIn && isCategoryRoute) {
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/category',
        builder: (context, state) => const CategoryScreen(),
      ),
      // Shell route for bottom navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const DashboardScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/checkin',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const CheckinScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/nearby',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const NearbyScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/tracker',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const TrackerScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const ProfileScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
        ],
      ),
      // Non-shell routes
      GoRoute(
        path: '/recommendations',
        builder: (context, state) => const RecommendationsScreen(),
      ),
      GoRoute(
        path: '/meditation',
        builder: (context, state) => const MeditationScreen(),
      ),
      GoRoute(
        path: '/breathing',
        builder: (context, state) => const BreathingScreen(),
      ),
      GoRoute(
        path: '/mood-history',
        builder: (context, state) => const MoodHistoryScreen(),
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AppointmentsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
