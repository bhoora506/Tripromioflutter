import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles Firebase Cloud Messaging (FCM) lifecycle for Tripromio.
///
/// Responsibilities (Phase H1-A):
///   - Request notification permission (Android 13+ / iOS).
///   - Obtain the FCM registration token.
///   - Listen for token refresh events.
///   - Listen for foreground messages and log basic metadata.
///
/// NOT in scope for this phase:
///   - Sending the token to the Laravel backend.
///   - Local notification UI (flutter_local_notifications).
///   - Navigation on notification tap.
///   - Chat / Trips / Connections business logic.
///
/// Usage (called once from [main] after [Firebase.initializeApp]):
/// ```dart
/// await PushNotificationService.instance.initialize();
/// ```
class PushNotificationService {
  PushNotificationService._();

  /// Singleton — FCM state should be app-wide.
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Initialise FCM:
  ///   1. Request notification permission.
  ///   2. Obtain and log the FCM token (development only).
  ///   3. Subscribe to token-refresh events.
  ///   4. Subscribe to foreground messages.
  ///
  /// This method is intentionally non-throwing — all errors are caught and
  /// logged so that a FCM failure never crashes the app or blocks startup.
  Future<void> initialize() async {
    await _requestPermission();
    await _fetchAndLogToken();
    _listenTokenRefresh();
    _listenForegroundMessages();
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  /// Requests notification permission.
  ///
  /// On Android 13+ (API 33+) this triggers the OS permission dialog once.
  /// On older Android versions the call is a no-op (permission is granted
  /// implicitly via the manifest declaration).
  /// On iOS this shows the system alert sheet.
  ///
  /// The result is logged for development; no UI feedback is shown in this
  /// phase.  The permission is NOT re-requested if already granted/denied.
  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        // Keeping provisional/criticalAlert/announcement false — we only need
        // standard push notifications for this phase.
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      final status = settings.authorizationStatus;
      // ignore: avoid_print
      print('[FCM] Notification permission status: $status');
    } catch (e) {
      // Non-fatal — the app works without notification permission.
      // ignore: avoid_print
      print('[FCM] Permission request error (non-fatal): $e');
    }
  }

  // ── Token retrieval ────────────────────────────────────────────────────────

  /// Fetches the current FCM registration token and logs it.
  ///
  /// The token is printed to the console for local development verification
  /// only.  This debug logging should be removed / hidden behind a
  /// [kDebugMode] guard before a production release.
  ///
  /// IMPORTANT: The FCM token is a device identifier — do NOT log it together
  /// with user credentials or other PII.
  Future<void> _fetchAndLogToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        // TODO(phase-H1-B): send [token] to the Laravel backend.
        // ignore: avoid_print
        print('[FCM] Registration token: $token');
      } else {
        // ignore: avoid_print
        print('[FCM] Token is null — device may not support FCM.');
      }
    } catch (e) {
      // Non-fatal — token retrieval can fail on emulators or when Google
      // Play Services are unavailable.
      // ignore: avoid_print
      print('[FCM] Token fetch error (non-fatal): $e');
    }
  }

  // ── Token refresh ──────────────────────────────────────────────────────────

  /// Subscribes to FCM token-refresh events.
  ///
  /// Tokens rotate when the app is restored from a backup, or when the user
  /// clears app data.  When this fires the new token should eventually be
  /// sent to the backend (Phase H1-B).
  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen(
      (newToken) {
        // TODO(phase-H1-B): send [newToken] to the Laravel backend.
        // ignore: avoid_print
        print('[FCM] Token refreshed: $newToken');
      },
      onError: (Object e) {
        // Non-fatal.
        // ignore: avoid_print
        print('[FCM] Token refresh stream error (non-fatal): $e');
      },
    );
  }

  // ── Foreground messages ────────────────────────────────────────────────────

  /// Subscribes to messages received while the app is in the foreground.
  ///
  /// In this phase we only log basic metadata (title / body).
  /// We deliberately do NOT log the full [RemoteMessage] data map to avoid
  /// accidentally leaking sensitive payload content.
  ///
  /// Local notification UI (flutter_local_notifications) is NOT added here —
  /// that will be a separate phase once the backend sends real payloads.
  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        final notification = message.notification;
        // ignore: avoid_print
        print(
          '[FCM] Foreground message received — '
          'title: ${notification?.title ?? "(none)"}, '
          'body: ${notification?.body ?? "(none)"}',
        );
        // TODO(phase-H1-C): show a local notification or in-app banner.
      },
      onError: (Object e) {
        // Non-fatal.
        // ignore: avoid_print
        print('[FCM] Foreground message stream error (non-fatal): $e');
      },
    );
  }
}
