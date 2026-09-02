import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../presentation/screens/placeholder_screen.dart';

/// Central route generator for the application.
///
/// As screens are built, replace the [PlaceholderScreen] entries with the
/// real screen widgets. Use [AppRoutes] constants for all route names.
abstract final class AppRouter {
  /// Returns the [RouteFactory] to pass to [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.splash => const PlaceholderScreen(label: 'Splash'),
      AppRoutes.onboarding => const PlaceholderScreen(label: 'Onboarding'),
      AppRoutes.login => const PlaceholderScreen(label: 'Login'),
      AppRoutes.register => const PlaceholderScreen(label: 'Register'),
      AppRoutes.home => const PlaceholderScreen(label: 'Home'),
      AppRoutes.profile => const PlaceholderScreen(label: 'Profile'),
      AppRoutes.trips => const PlaceholderScreen(label: 'Trips'),
      AppRoutes.tripDetail => const PlaceholderScreen(label: 'Trip Detail'),
      AppRoutes.createTrip => const PlaceholderScreen(label: 'Create Trip'),
      AppRoutes.discover => const PlaceholderScreen(label: 'Discover'),
      AppRoutes.matchDetail =>
        const PlaceholderScreen(label: 'Match Detail'),
      AppRoutes.conversations =>
        const PlaceholderScreen(label: 'Conversations'),
      AppRoutes.chat => const PlaceholderScreen(label: 'Chat'),
      _ => const PlaceholderScreen(label: '404 – Not Found'),
    };

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => page,
    );
  }
}
