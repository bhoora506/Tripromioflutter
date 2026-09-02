/// App-wide constants for Tripromio.
/// Group constants logically so they can be found and updated quickly.
abstract final class AppConstants {
  // ── App meta ──────────────────────────────────────────────────────────────
  static const String appName = 'Tripromio';
  static const String appVersion = '1.0.0';

  // ── API ───────────────────────────────────────────────────────────────────
  // Base URL is intentionally empty at this stage.
  // It will be populated from environment config / .env in a later phase.
  static const String apiBaseUrl = '';
  static const Duration apiTimeout = Duration(seconds: 30);

  // ── Padding & Spacing ─────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  /// Standard horizontal screen padding used on most screens.
  static const double screenPaddingH = 20.0;

  // ── Border radius ─────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ── Animation durations ───────────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ── Asset paths ───────────────────────────────────────────────────────────
  // These will be populated as assets are added in later phases.
  static const String assetsImages = 'assets/images/';
  static const String assetsIcons = 'assets/icons/';

  // ── Storage keys ─────────────────────────────────────────────────────────
  // Used for local storage / shared preferences keys.
  static const String keyAuthToken = 'auth_token';
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingDone = 'onboarding_done';
}
