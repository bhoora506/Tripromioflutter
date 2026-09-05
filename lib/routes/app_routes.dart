/// Named route identifiers for the entire application.
///
/// Add a new route constant here whenever a new screen is introduced.
/// This keeps all route names in a single, discoverable location.
abstract final class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Main shell ────────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String profile = '/profile';

  // ── Trips ─────────────────────────────────────────────────────────────────
  static const String trips = '/trips';
  static const String tripDetail = '/trips/:tripId';
  static const String createTrip = '/trips/create';

  // ── Matching / Companions ──────────────────────────────────────────────────────
  static const String findCompanions = '/find-companions';
  static const String searchResults = '/find-companions/results';
  static const String discover = '/discover';
  static const String matchDetail = '/discover/match';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const String conversations = '/conversations';
  static const String chat = '/conversations/chat';
}
