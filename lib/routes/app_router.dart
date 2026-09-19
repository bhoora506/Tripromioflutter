import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/companions/find_companions_screen.dart';
import '../presentation/screens/companions/search_results_screen.dart';
import '../presentation/screens/companions/companion_detail_screen.dart';
import '../presentation/screens/connections/connection_requests_screen.dart';
import '../presentation/screens/connections/conversations_screen.dart';
import '../presentation/screens/connections/my_connections_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/placeholder_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/edit_interests_screen.dart';
import '../presentation/screens/profile/preferred_destinations_screen.dart';
import '../presentation/screens/profile/travel_availability_screen.dart';
import '../data/models/interest_model.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/trips/create_trip_screen.dart';
import '../presentation/screens/trips/edit_trip_screen.dart';
import '../presentation/screens/trips/my_trips_screen.dart';
import '../presentation/screens/trips/trip_details_screen.dart';
import '../presentation/screens/trips/trip_join_requests_screen.dart';
import '../presentation/screens/trips/trip_members_screen.dart';

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

      // ── Profile ────────────────────────────────────────────────────────────
      AppRoutes.profile => const ProfileScreen(),
      AppRoutes.editProfile => const EditProfileScreen(),
      AppRoutes.preferredDestinations => const PreferredDestinationsScreen(),
      AppRoutes.travelAvailability => const TravelAvailabilityScreen(),
      AppRoutes.editInterests => EditInterestsScreen(
        currentInterests: settings.arguments as List<InterestModel>? ?? [],
      ),

      // ── Trips ────────────────────────────────────────────────────────────────
      AppRoutes.trips => const MyTripsScreen(),
      AppRoutes.createTrip => const CreateTripScreen(),
      AppRoutes.editTrip => const EditTripScreen(),
      AppRoutes.tripJoinRequests => const TripJoinRequestsScreen(),
      AppRoutes.tripMembers => const TripMembersScreen(),

      // ── Phase 5 — Companion Flow ───────────────────────────────────────────
      // /find-companions → FindCompanionsScreen (form)
      AppRoutes.findCompanions => const FindCompanionsScreen(),
      // /discover → SearchResultsScreen (FindCompanionsScreen navigates here)
      AppRoutes.discover => const SearchResultsScreen(),
      // /trips/:tripId → TripDetailsScreen
      AppRoutes.tripDetail => const TripDetailsScreen(),
      AppRoutes.companionDetail => const CompanionDetailScreen(),
      AppRoutes.myConnections => const MyConnectionsScreen(),
      AppRoutes.connectionRequests => const ConnectionRequestsScreen(),
      AppRoutes.conversations => const ConversationsScreen(),
      // NOTE: ConversationDetailScreen is opened via MaterialPageRoute with a
      // ConversationModel constructor arg — not a named route.

      _ => const PlaceholderScreen(label: '404 – Not Found'),
    };

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => page,
    );
  }
}
