import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/trip_model.dart';

/// Service for trip-related API calls.
///
/// Wraps [ApiClient] — the UI never touches the HTTP layer directly.
///
/// Endpoints covered:
///   GET    /api/trips               → [getTrips]      (discover)
///   GET    /api/trips/{id}          → [getTrip]        (single)
///   POST   /api/trips               → [createTrip]
///   PUT    /api/trips/{id}          → [updateTrip]
///   GET    /api/my/trips            → [getMyTrips]
///   POST   /api/trips/{id}/publish  → [publishTrip]
///   POST   /api/trips/{id}/cancel   → [cancelTrip]
class TripService {
  TripService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ── GET /api/trips (Discover) ──────────────────────────────────────────────

  /// Fetch published trips for discovery.
  ///
  /// All filter parameters are optional. Backend defaults:
  ///   • Only published trips (excludes current user's own trips and past trips)
  ///   • Sorting: `start_date` ASC, `id` ASC
  ///   • Pagination: page 1, 20 per page (max 50)
  ///
  /// Throws [ApiException] subclasses on failure.
  Future<PaginatedTripsModel> getTrips({
    String? destination,
    String? startDate,
    String? endDate,
    double? budgetMin,
    double? budgetMax,
    TripType? tripType,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{};

    if (destination != null && destination.isNotEmpty) {
      queryParams['destination'] = destination;
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }
    if (budgetMin != null) {
      queryParams['budget_min'] = budgetMin.toString();
    }
    if (budgetMax != null) {
      queryParams['budget_max'] = budgetMax.toString();
    }
    if (tripType != null) {
      queryParams['trip_type'] = tripType.apiValue;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }
    queryParams['page'] = page.toString();
    queryParams['per_page'] = perPage.toString();

    final response = await _client.get(
      ApiConstants.trips,
      queryParams: queryParams,
    );

    return PaginatedTripsModel.fromJson(response.dataAsMap);
  }

  // ── GET /api/trips/{id} ────────────────────────────────────────────────────

  /// Fetch a single trip by its ID.
  ///
  /// Throws [NotFoundException] (404) if the trip does not exist.
  Future<TripModel> getTrip(int tripId) async {
    final response = await _client.get(ApiConstants.tripById(tripId));

    final data = response.dataAsMap;
    final tripJson = data['trip'] as Map<String, dynamic>?;
    if (tripJson == null) {
      return TripModel.fromJson(data);
    }
    return TripModel.fromJson(tripJson);
  }

  // ── POST /api/trips ───────────────────────────────────────────────────────

  /// Create a new trip.
  ///
  /// Required fields: [title], [destination], [startDate], [endDate],
  /// [tripType], [maxMembers].
  ///
  /// Throws [ValidationException] (422) if validation fails.
  Future<TripModel> createTrip({
    required String title,
    required String destination,
    String? placeId,
    double? latitude,
    double? longitude,
    required String startDate,
    required String endDate,
    double? budgetMin,
    double? budgetMax,
    required TripType tripType,
    String? description,
    required int maxMembers,
    List<int>? interestIds,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'destination': destination,
      'start_date': startDate,
      'end_date': endDate,
      'trip_type': tripType.apiValue,
      'max_members': maxMembers,
    };

    if (placeId != null) body['place_id'] = placeId;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (budgetMin != null) body['budget_min'] = budgetMin;
    if (budgetMax != null) body['budget_max'] = budgetMax;
    if (description != null) body['description'] = description;
    if (interestIds != null) body['interest_ids'] = interestIds;

    final response = await _client.post(ApiConstants.trips, body: body);

    final data = response.dataAsMap;
    final tripJson = data['trip'] as Map<String, dynamic>?;
    if (tripJson == null) {
      return TripModel.fromJson(data);
    }
    return TripModel.fromJson(tripJson);
  }

  // ── PUT /api/trips/{id} ───────────────────────────────────────────────────

  /// Update an existing trip.
  ///
  /// Only fields that are explicitly provided are sent to the backend.
  /// Omitted fields are left unchanged on the server.
  ///
  /// **Special `interest_ids` behaviour:**
  ///   • Provided with values → full sync (replaces all interests).
  ///   • Provided as `[]` → removes all interests.
  ///   • Omitted (`null`) → keeps existing interests.
  ///
  /// Throws [ConflictException] (409) if the trip is completed or cancelled.
  Future<TripModel> updateTrip(
    int tripId, {
    String? title,
    String? destination,
    String? placeId,
    double? latitude,
    double? longitude,
    String? startDate,
    String? endDate,
    double? budgetMin,
    double? budgetMax,
    TripType? tripType,
    String? description,
    int? maxMembers,
    List<int>? interestIds,
  }) async {
    // Only include fields that are explicitly supplied — PATCH-like semantics.
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (destination != null) body['destination'] = destination;
    if (placeId != null) body['place_id'] = placeId;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (startDate != null) body['start_date'] = startDate;
    if (endDate != null) body['end_date'] = endDate;
    if (budgetMin != null) body['budget_min'] = budgetMin;
    if (budgetMax != null) body['budget_max'] = budgetMax;
    if (tripType != null) body['trip_type'] = tripType.apiValue;
    if (description != null) body['description'] = description;
    if (maxMembers != null) body['max_members'] = maxMembers;
    if (interestIds != null) body['interest_ids'] = interestIds;

    final response = await _client.put(
      ApiConstants.tripById(tripId),
      body: body,
    );

    final data = response.dataAsMap;
    final tripJson = data['trip'] as Map<String, dynamic>?;
    if (tripJson == null) {
      return TripModel.fromJson(data);
    }
    return TripModel.fromJson(tripJson);
  }

  // ── GET /api/my/trips ─────────────────────────────────────────────────────

  /// Fetch trips owned by the current authenticated user.
  ///
  /// The backend hardcodes `per_page = 15` — do NOT send a configurable
  /// per_page parameter.
  ///
  /// Returns all statuses (draft, published, ongoing, completed, cancelled).
  Future<PaginatedTripsModel> getMyTrips({
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
    };

    final response = await _client.get(
      ApiConstants.myTrips,
      queryParams: queryParams,
    );

    return PaginatedTripsModel.fromJson(response.dataAsMap);
  }

  // ── POST /api/trips/{id}/publish ──────────────────────────────────────────

  /// Publish a draft trip.
  ///
  /// Throws [ConflictException] (409) if the trip is not in draft status.
  /// Throws [ValidationException] (422) if required fields are missing.
  Future<TripModel> publishTrip(int tripId) async {
    final response = await _client.post(
      ApiConstants.tripAction(tripId, 'publish'),
    );

    final data = response.dataAsMap;
    final tripJson = data['trip'] as Map<String, dynamic>?;
    if (tripJson == null) {
      return TripModel.fromJson(data);
    }
    return TripModel.fromJson(tripJson);
  }

  // ── POST /api/trips/{id}/cancel ───────────────────────────────────────────

  /// Cancel a trip.
  ///
  /// Allowed for trips in draft, published, or ongoing status.
  ///
  /// Throws [ConflictException] (409) if the trip is completed or cancelled.
  Future<TripModel> cancelTrip(int tripId) async {
    final response = await _client.post(
      ApiConstants.tripAction(tripId, 'cancel'),
    );

    final data = response.dataAsMap;
    final tripJson = data['trip'] as Map<String, dynamic>?;
    if (tripJson == null) {
      return TripModel.fromJson(data);
    }
    return TripModel.fromJson(tripJson);
  }

  /// Release resources.  Call when the service is no longer needed.
  void dispose() => _client.dispose();
}
