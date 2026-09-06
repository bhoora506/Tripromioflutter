import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Service for profile-related API calls.
///
/// Wraps [ApiClient] — the UI never touches the HTTP layer directly.
///
/// Endpoints covered:
///   GET    /api/profile        → [getProfile]
///   PUT    /api/profile        → [updateProfile]
///   POST   /api/profile/photo  → [uploadProfilePhoto]
///   DELETE /api/profile/photo  → [deleteProfilePhoto]
class ProfileService {
  ProfileService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ── GET /api/profile ──────────────────────────────────────────────────────

  /// Fetch the full profile for the currently authenticated user.
  ///
  /// The backend returns a standard success envelope:
  ///   { "success": true, "data": { "user": { ... } } }
  ///
  /// Throws [ApiException] subclasses on failure.
  Future<UserModel> getProfile() async {
    final response = await _client.get(ApiConstants.profile);

    // Backend wraps the user object under data.user
    final data = response.dataAsMap;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (userJson == null) {
      // Some endpoints return the user directly at the top level of data
      // Try treating the whole data map as the user
      return UserModel.fromJson(data);
    }

    return UserModel.fromJson(userJson);
  }

  // ── PUT /api/profile ──────────────────────────────────────────────────────

  /// Update the authenticated user's profile.
  ///
  /// Only non-null fields are sent to the backend.
  /// The backend returns the updated user in the same envelope.
  ///
  /// Allowed fields (all optional):
  ///   bio, city, country, languages, travel_style,
  ///   preferred_budget_min, preferred_budget_max
  ///
  /// Throws [ApiException] (including [ValidationException] for 422) on error.
  Future<UserModel> updateProfile({
    String? bio,
    String? city,
    String? country,
    List<String>? languages,
    String? travelStyle,
    double? preferredBudgetMin,
    double? preferredBudgetMax,
  }) async {
    // Build the request body with only provided (non-null) fields.
    final body = <String, dynamic>{};
    if (bio != null) body['bio'] = bio;
    if (city != null) body['city'] = city;
    if (country != null) body['country'] = country;
    if (languages != null) body['languages'] = languages;
    if (travelStyle != null) body['travel_style'] = travelStyle;
    if (preferredBudgetMin != null) {
      body['preferred_budget_min'] = preferredBudgetMin;
    }
    if (preferredBudgetMax != null) {
      body['preferred_budget_max'] = preferredBudgetMax;
    }

    final response = await _client.put(ApiConstants.profile, body: body);

    final data = response.dataAsMap;
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      return UserModel.fromJson(data);
    }
    return UserModel.fromJson(userJson);
  }

  // ── POST /api/profile/photo ───────────────────────────────────────────────

  /// Upload a new profile photo.
  ///
  /// [filePath] must be the absolute path to the selected image file.
  ///
  /// Sends a multipart/form-data POST with field name `photo`.
  /// The backend accepts jpeg, jpg, png, webp up to 5 MB.
  ///
  /// Returns the updated [UserModel] containing the new [profile_photo_url].
  ///
  /// Throws [ApiException] subclasses on failure (including [ValidationException]
  /// for 422 if the file is invalid or too large).
  Future<UserModel> uploadProfilePhoto(String filePath) async {
    final response = await _client.postMultipart(
      ApiConstants.profilePhoto,
      fileField: 'photo',
      filePath: filePath,
    );

    final data = response.dataAsMap;
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      return UserModel.fromJson(data);
    }
    return UserModel.fromJson(userJson);
  }

  // ── DELETE /api/profile/photo ─────────────────────────────────────────────

  /// Remove the current profile photo.
  ///
  /// Sends an authenticated DELETE to /api/profile/photo.
  /// On success, re-fetches the profile so the caller receives the
  /// updated [UserModel] with [profile_photo_url] cleared.
  ///
  /// Throws [ApiException] subclasses on failure.
  Future<UserModel> deleteProfilePhoto() async {
    await _client.delete(ApiConstants.profilePhoto);
    // Re-fetch the profile to get the authoritative cleared state.
    return getProfile();
  }

  void dispose() => _client.dispose();
}
