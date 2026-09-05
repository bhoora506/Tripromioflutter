import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure persistent storage for the Sanctum Bearer token.
///
/// Uses [FlutterSecureStorage] which stores credentials in:
///   - Android Keystore (Android)
///   - iOS Keychain (iOS)
///
/// NEVER use SharedPreferences or plain text for auth tokens.
///
/// Usage:
/// ```dart
/// final storage = TokenStorage();
/// await storage.saveToken(token);
/// final token = await storage.getToken();
/// ```
class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'tripromio_auth_token';

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Persist [token] securely.  Overwrites any existing value.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the stored token, or `null` if none is present.
  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// Returns `true` if a token is currently stored.
  Future<bool> hasToken() async {
    final value = await _storage.read(key: _tokenKey);
    return value != null && value.isNotEmpty;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Remove the stored token (e.g., on logout).
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
