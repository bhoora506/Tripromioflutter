import 'interest_model.dart';

// ── Trip Type ────────────────────────────────────────────────────────────────

/// Trip categories defined by the backend.
///
/// Dart enum values use camelCase; the [apiValue] getter returns the
/// snake_case string expected by the API.
enum TripType {
  weekend,
  adventure,
  backpacking,
  roadTrip,
  nature,
  photography,
  cultural,
  beach,
  mountains,
  other;

  /// The exact string the backend expects (e.g. `road_trip`).
  String get apiValue {
    switch (this) {
      case TripType.roadTrip:
        return 'road_trip';
      default:
        return name;
    }
  }

  /// Parse a backend string into a [TripType].
  ///
  /// Returns `null` for unrecognised values so callers can decide on a
  /// fallback without crashing.
  static TripType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'weekend':
        return TripType.weekend;
      case 'adventure':
        return TripType.adventure;
      case 'backpacking':
        return TripType.backpacking;
      case 'road_trip':
        return TripType.roadTrip;
      case 'nature':
        return TripType.nature;
      case 'photography':
        return TripType.photography;
      case 'cultural':
        return TripType.cultural;
      case 'beach':
        return TripType.beach;
      case 'mountains':
        return TripType.mountains;
      case 'other':
        return TripType.other;
      default:
        return null;
    }
  }
}

// ── Trip Status ──────────────────────────────────────────────────────────────

/// Lifecycle statuses a trip can be in.
enum TripStatus {
  draft,
  published,
  ongoing,
  completed,
  cancelled,

  /// Fallback for any status value the client does not recognise.
  unknown;

  /// Parse a backend string into a [TripStatus].
  ///
  /// Returns [TripStatus.unknown] for unrecognised values to prevent crashes.
  static TripStatus fromString(String? value) {
    if (value == null) return TripStatus.unknown;
    switch (value) {
      case 'draft':
        return TripStatus.draft;
      case 'published':
        return TripStatus.published;
      case 'ongoing':
        return TripStatus.ongoing;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.unknown;
    }
  }
}

// ── Trip Owner ───────────────────────────────────────────────────────────────

/// Lightweight owner embedded in a [TripResource].
///
/// Only contains `id` and `name` — intentionally NOT the full [UserModel]
/// because the Trip API does not return the full user shape.
class TripOwnerModel {
  const TripOwnerModel({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory TripOwnerModel.fromJson(Map<String, dynamic> json) {
    return TripOwnerModel(
      id: _parseInt(json['id']),
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  String toString() => 'TripOwnerModel(id: $id, name: $name)';
}

// ── Trip Model ───────────────────────────────────────────────────────────────

/// Represents a single Trip as returned by the backend `TripResource`.
///
/// Parsing is intentionally defensive:
///   • `latitude`, `longitude`, `budget_min`, `budget_max` may arrive as
///     JSON strings → parsed via [double.tryParse].
///   • `owner` may be `null`.
///   • `interests` may be an empty array.
///   • Unknown `trip_type` / `status` values will not crash the app.
class TripModel {
  const TripModel({
    required this.id,
    required this.title,
    required this.destination,
    this.placeId,
    this.latitude,
    this.longitude,
    this.startDate,
    this.endDate,
    this.budgetMin,
    this.budgetMax,
    this.tripType,
    this.description,
    required this.maxMembers,
    required this.status,
    this.owner,
    this.interests = const [],
    required this.memberCount,
    required this.remainingSlots,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String destination;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? startDate;
  final String? endDate;
  final double? budgetMin;
  final double? budgetMax;
  final TripType? tripType;
  final String? description;
  final int maxMembers;
  final TripStatus status;
  final TripOwnerModel? owner;
  final List<InterestModel> interests;
  final int memberCount;
  final int remainingSlots;
  final String? createdAt;
  final String? updatedAt;

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: _parseInt(json['id']),
      title: json['title'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      placeId: json['place_id'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      budgetMin: _parseDouble(json['budget_min']),
      budgetMax: _parseDouble(json['budget_max']),
      tripType: TripType.fromString(json['trip_type'] as String?),
      description: json['description'] as String?,
      maxMembers: _parseInt(json['max_members']),
      status: TripStatus.fromString(json['status'] as String?),
      owner: json['owner'] != null
          ? TripOwnerModel.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((i) => InterestModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      memberCount: _parseInt(json['member_count']),
      remainingSlots: _parseInt(json['remaining_slots']),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'destination': destination,
        'place_id': placeId,
        'latitude': latitude,
        'longitude': longitude,
        'start_date': startDate,
        'end_date': endDate,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'trip_type': tripType?.apiValue,
        'description': description,
        'max_members': maxMembers,
        'status': status.name,
        'owner': owner?.toJson(),
        'interests': interests.map((e) => e.toJson()).toList(),
        'member_count': memberCount,
        'remaining_slots': remainingSlots,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  String toString() =>
      'TripModel(id: $id, title: $title, destination: $destination, '
      'status: ${status.name})';
}

// ── Pagination ───────────────────────────────────────────────────────────────

/// Standard pagination metadata returned by list endpoints.
class PaginationModel {
  const PaginationModel({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
  });

  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: _parseInt(json['total']),
      perPage: _parseInt(json['per_page']),
      currentPage: _parseInt(json['current_page']),
      lastPage: _parseInt(json['last_page']),
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'per_page': perPage,
        'current_page': currentPage,
        'last_page': lastPage,
        'has_more': hasMore,
      };

  @override
  String toString() =>
      'PaginationModel(page: $currentPage/$lastPage, total: $total)';
}

// ── Paginated Trips Response ─────────────────────────────────────────────────

/// Wraps a list of [TripModel] items with [PaginationModel] metadata.
///
/// Used by both `GET /api/trips` (discover) and `GET /api/my/trips`.
class PaginatedTripsModel {
  const PaginatedTripsModel({
    required this.items,
    required this.pagination,
  });

  final List<TripModel> items;
  final PaginationModel pagination;

  factory PaginatedTripsModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final paginationJson =
        json['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return PaginatedTripsModel(
      items: itemsList
          .map((i) => TripModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(paginationJson),
    );
  }

  @override
  String toString() =>
      'PaginatedTripsModel(${items.length} items, $pagination)';
}

// ── Shared safe parsers ──────────────────────────────────────────────────────

/// Parse a value that may be `int`, `String`, or `num` into an [int].
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is num) return value.toInt();
  return 0;
}

/// Parse a value that may be `double`, `int`, `String`, or `num` into
/// a nullable [double].
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  if (value is num) return value.toDouble();
  return null;
}
