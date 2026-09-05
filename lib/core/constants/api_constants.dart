/// Centralised API configuration for the Tripromio application.
///
/// NEVER scatter URLs or path strings throughout the code.
/// All endpoint paths and the base URL live here so they can be
/// updated in one place (e.g., switching from dev to production).
abstract final class ApiConstants {
  // ── Base URLs ─────────────────────────────────────────────────────────────

  /// Android Emulator loopback to the host machine.
  /// Laravel runs on the host via `php artisan serve` (port 8000).
  static const String _baseUrlDev = 'http://10.0.2.2:8000/api';

  /// Production URL – update this before releasing.
  static const String _baseUrlProd = 'https://api.tripromio.com/api';

  /// Active base URL for the current build.
  /// Change [_useProd] to true when building a production release.
  static const bool _useProd = false;
  static const String baseUrl = _useProd ? _baseUrlProd : _baseUrlDev;

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Headers ───────────────────────────────────────────────────────────────
  static const String headerAccept = 'Accept';
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';

  static const String mimeJson = 'application/json';
  static const String mimeFormData = 'multipart/form-data';

  // ── Auth endpoints ────────────────────────────────────────────────────────
  static const String health = '/health';

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';

  static const String emailVerify = '/email/verify';
  static const String emailResend = '/email/verification-notification';

  // ── Profile endpoints ─────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String profileInterests = '/profile/interests';
  static const String profilePhoto = '/profile/photo';
  static const String profileDestinations = '/profile/destinations';
  static const String profileAvailability = '/profile/availability';

  // ── Interest reference data ───────────────────────────────────────────────
  static const String interests = '/interests';

  // ── Trip endpoints ────────────────────────────────────────────────────────
  static const String trips = '/trips';
  static const String myTrips = '/my/trips';

  /// Build a trip-specific path, e.g. '/trips/42'.
  static String tripById(int id) => '/trips/$id';

  /// Build a trip action path, e.g. '/trips/42/publish'.
  static String tripAction(int id, String action) => '/trips/$id/$action';
}
