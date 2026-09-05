import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/companions/find_companions_screen.dart';
import '../presentation/screens/companions/search_results_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/placeholder_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/trips/trip_details_screen.dart';

/// Central route generator for the application.
///
/// As screens are built, replace the [PlaceholderScreen] entries with the
/// real screen widgets. Use [AppRoutes] constants for all route names.
abstract final class AppRouter {
  /// Returns the [RouteFactory] to pass to [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      // ── Core ──────────────────────────────────────────────────────────────
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.onboarding => const OnboardingScreen(),
      AppRoutes.home => const HomeScreen(),

      // ── Auth ────────────────────────────────────────────────────────
      AppRoutes.login => const LoginScreen(),
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.forgotPassword => const ForgotPasswordScreen(),

      // ── Profile / Trips (placeholder until later phases) ──────────────────
      AppRoutes.profile => const PlaceholderScreen(label: 'Profile'),
      AppRoutes.trips => const PlaceholderScreen(label: 'Trips'),
      AppRoutes.createTrip => const PlaceholderScreen(label: 'Create Trip'),

      // ── Phase 5 — Companion Flow ───────────────────────────────────────────
      // /find-companions → FindCompanionsScreen (form)
      AppRoutes.findCompanions => const FindCompanionsScreen(),
      // /discover → SearchResultsScreen (FindCompanionsScreen navigates here)
      AppRoutes.discover => const SearchResultsScreen(),
      // /trips/:tripId → TripDetailsScreen
      AppRoutes.tripDetail => const TripDetailsScreen(),

      // ── Future screens (placeholders) ─────────────────────────────────────
      AppRoutes.matchDetail => const PlaceholderScreen(label: 'Match Detail'),
      AppRoutes.conversations => const PlaceholderScreen(label: 'Conversations'),
      AppRoutes.chat => const PlaceholderScreen(label: 'Chat'),

      _ => const PlaceholderScreen(label: '404 – Not Found'),
    };

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => page,
    );
  }
}
