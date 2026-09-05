import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../models/user_model.dart';

/// Result object returned by [AuthService] login/register calls.
class AuthResult {
  const AuthResult({required this.user, required this.token});
  final UserModel user;
  final String token;
}

/// Service for all authentication-related API calls.
///
/// Wraps [ApiClient] and [TokenStorage] — the UI never touches those directly.
///
/// Usage:
/// ```dart
/// final service = AuthService();
/// final result = await service.login(email: 'a@b.com', password: 'Secret@1');
/// ```
class AuthService {
  AuthService({ApiClient? client, TokenStorage? tokenStorage})
      : _client = client ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  // ── Register ──────────────────────────────────────────────────────────────

  /// Register a new user account.
  ///
  /// On success the Sanctum token is saved to secure storage and an
  /// [AuthResult] is returned.
  ///
  /// Throws [ApiException] subclasses on failure.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      ApiConstants.authRegister,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = response.dataAsMap;
    final token = data['token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (token == null || userJson == null) {
      throw const ServerException('Unexpected response from register endpoint.');
    }

    await _tokenStorage.saveToken(token);
    return AuthResult(user: UserModel.fromJson(userJson), token: token);
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Authenticate an existing user.
  ///
  /// On success the Sanctum token is saved to secure storage and an
  /// [AuthResult] is returned.
  ///
  /// Throws [ApiException] subclasses on failure.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.authLogin,
      body: {'email': email, 'password': password},
    );

    final data = response.dataAsMap;
    final token = data['token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (token == null || userJson == null) {
      throw const ServerException('Unexpected response from login endpoint.');
    }

    await _tokenStorage.saveToken(token);
    return AuthResult(user: UserModel.fromJson(userJson), token: token);
  }

  // ── Current user ──────────────────────────────────────────────────────────

  /// Fetch the currently authenticated user from the backend.
  ///
  /// Requires a valid stored token.
  Future<UserModel> getCurrentUser() async {
    final response = await _client.get(ApiConstants.authMe);
    final userJson = response.dataAsMap['user'] as Map<String, dynamic>?;

    if (userJson == null) {
      throw const ServerException('Unexpected response from /auth/me.');
    }

    return UserModel.fromJson(userJson);
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// Log the user out.
  ///
  /// Calls the backend logout endpoint to revoke the Sanctum token,
  /// then deletes the local token regardless of whether the network call
  /// succeeded (to prevent stale auth state).
  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.authLogout);
    } on NetworkException {
      // Network unreachable — still clear local token below.
    } on ApiException {
      // Backend error — still clear local token below.
    } finally {
      await _tokenStorage.deleteToken();
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  /// Request a password reset email.
  ///
  /// Always returns success per backend design (prevents user enumeration).
  /// Returns the backend message string to display to the user.
  Future<String> forgotPassword({required String email}) async {
    final response = await _client.post(
      ApiConstants.authForgotPassword,
      body: {'email': email},
    );
    return response.message;
  }

  void dispose() => _client.dispose();
}
