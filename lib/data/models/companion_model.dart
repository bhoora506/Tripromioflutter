import 'interest_model.dart';
import 'preferred_destination_model.dart';
import 'trip_model.dart' show PaginationModel;

// ── Companion Model ───────────────────────────────────────────────────────────

/// Discovery-safe companion profile as returned by GET /api/companions.
///
/// Privacy rules (enforced by backend, mirrored here):
///   - email is NEVER present
///   - budget preferences are NOT present
///   - profile_completion is NOT present
///   - travel availability is NOT present
///   - is_discoverable flag is NOT present
class CompanionModel {
  const CompanionModel({
    required this.id,
    required this.name,
    this.profilePhotoUrl,
    this.bio,
    this.city,
    this.country,
    this.languages = const [],
    this.travelStyle,
    this.interests = const [],
    this.preferredDestinations = const [],
  });

  final int id;
  final String name;
  final String? profilePhotoUrl;
  final String? bio;
  final String? city;
  final String? country;
  final List<String> languages;
  final String? travelStyle;
  final List<InterestModel> interests;
  final List<PreferredDestinationModel> preferredDestinations;

  /// Convenience: city/country formatted as "City, Country" or just one if the
  /// other is null. Returns null if both are null.
  String? get location {
    if (city != null && country != null) return '$city, $country';
    return city ?? country;
  }

  factory CompanionModel.fromJson(Map<String, dynamic> json) {
    return CompanionModel(
      id: _parseInt(json['id']),
      name: json['name'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      languages: (json['languages'] as List<dynamic>?)
              ?.map((l) => l.toString())
              .toList() ??
          [],
      travelStyle: json['travel_style'] as String?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((i) => InterestModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      preferredDestinations: (json['preferred_destinations'] as List<dynamic>?)
              ?.map((d) =>
                  PreferredDestinationModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  String toString() => 'CompanionModel(id: $id, name: $name)';
}

// ── Paginated Companions Response ─────────────────────────────────────────────

/// Wraps a list of [CompanionModel] items with [PaginationModel] metadata.
/// Matches the GET /api/companions response envelope.
class PaginatedCompanionsModel {
  const PaginatedCompanionsModel({
    required this.items,
    required this.pagination,
  });

  final List<CompanionModel> items;
  final PaginationModel pagination;

  factory PaginatedCompanionsModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final paginationJson =
        json['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return PaginatedCompanionsModel(
      items: itemsList
          .map((i) => CompanionModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(paginationJson),
    );
  }

  @override
  String toString() =>
      'PaginatedCompanionsModel(${items.length} items, $pagination)';
}
