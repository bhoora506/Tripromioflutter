// Represents the authenticated user as returned by the Tripromio backend.
///
/// Matches the `UserResource` JSON shape from:
//   POST /api/auth/login
//   POST /api/auth/register
//   GET  /api/auth/me
///
// All nullable fields are optional in the backend response
/// (e.g. `profile` is null until the user completes it).
import 'interest_model.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.profile,
    this.interests = const [],
    this.profileCompletion = 0,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final UserProfileModel? profile;
  final List<InterestModel> interests;
  final int profileCompletion;
  final String createdAt;

  /// Whether the user has verified their email address.
  bool get isEmailVerified => emailVerifiedAt != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    return UserModel(
      id: parseInt(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailVerifiedAt: json['email_verified_at'] as String?,
      profile: json['profile'] != null
          ? UserProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((i) => InterestModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      profileCompletion: parseInt(json['profile_completion']),
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'email_verified_at': emailVerifiedAt,
        'profile': profile?.toJson(),
        'interests': interests.map((e) => e.toJson()).toList(),
        'profile_completion': profileCompletion,
        'created_at': createdAt,
      };

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';
}

/// Embedded profile data within [UserModel].
class UserProfileModel {
  const UserProfileModel({
    this.bio,
    this.city,
    this.country,
    this.languages = const [],
    this.travelStyle,
    this.profilePhotoUrl,
    this.preferredBudgetMin,
    this.preferredBudgetMax,
  });

  final String? bio;
  final String? city;
  final String? country;
  final List<String> languages;
  final String? travelStyle;
  final String? profilePhotoUrl;
  final double? preferredBudgetMin;
  final double? preferredBudgetMax;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return UserProfileModel(
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      languages: (json['languages'] as List<dynamic>?)
              ?.map((l) => l.toString())
              .toList() ??
          [],
      travelStyle: json['travel_style'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      preferredBudgetMin: parseDouble(json['preferred_budget_min']),
      preferredBudgetMax: parseDouble(json['preferred_budget_max']),
    );
  }

  Map<String, dynamic> toJson() => {
        'bio': bio,
        'city': city,
        'country': country,
        'languages': languages,
        'travel_style': travelStyle,
        'profile_photo_url': profilePhotoUrl,
        'preferred_budget_min': preferredBudgetMin,
        'preferred_budget_max': preferredBudgetMax,
      };
}
