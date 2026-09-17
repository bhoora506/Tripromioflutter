import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/companion_model.dart';

/// Service for companion discovery API calls.
///
/// Endpoints covered:
///   GET /api/companions → [getCompanions]
///
/// Query parameters are validated by [CompanionDiscoveryRequest] on the backend.
/// Only send parameters that the backend explicitly supports.
class CompanionService {
  CompanionService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ── GET /api/companions ───────────────────────────────────────────────────

  /// Fetch the paginated companion discovery feed.
  ///
  /// All filter parameters are optional.
  ///
  /// Backend-supported filters (from CompanionDiscoveryRequest):
  ///   • destination   – text match against preferred_destinations.destination
  ///   • place_id      – exact Google Places ID match
  ///   • start_date    – yyyy-MM-dd
  ///   • end_date      – yyyy-MM-dd, must be >= start_date
  ///   • travel_style  – must match a valid TravelStyle enum value
  ///   • interest_ids  – array of int IDs (sent as interest_ids[]=1&interest_ids[]=2)
  ///   • sort          – 'profile_completion' (default) or 'newest'
  ///   • page          – 1-based page index
  ///   • per_page      – results per page, max 50
  ///
  /// Throws [ApiException] subclasses on failure.
  Future<PaginatedCompanionsModel> getCompanions({
    String? destination,
    String? placeId,
    DateTime? startDate,
    DateTime? endDate,
    String? travelStyle,
    List<int>? interestIds,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{};

    if (destination != null && destination.isNotEmpty) {
      queryParams['destination'] = destination;
    }
    if (placeId != null && placeId.isNotEmpty) {
      queryParams['place_id'] = placeId;
    }
    if (startDate != null) {
      queryParams['start_date'] = _dateToApi(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = _dateToApi(endDate);
    }
    if (travelStyle != null && travelStyle.isNotEmpty) {
      queryParams['travel_style'] = travelStyle;
    }
    // Backend expects array notation: interest_ids[]=1&interest_ids[]=2
    // The http package's Uri.replace(queryParameters:...) does not support
    // duplicate keys. We build the array params manually and append.
    // NOTE: we pass them through the standard queryParams dict keyed as
    // 'interest_ids[]' is not supported by Map — so we build the URI ourselves
    // for interest_ids (handled in _buildWithArrayParam below).
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }
    queryParams['page'] = page.toString();
    queryParams['per_page'] = perPage.toString();

    final response = await _client.get(
      _buildCompanionsPath(queryParams, interestIds),
    );

    return PaginatedCompanionsModel.fromJson(response.dataAsMap);
  }

  /// Converts DateTime to yyyy-MM-dd string expected by Laravel validation.
  String _dateToApi(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Returns a path with query string pre-built, bypassing Map&lt;String,String&gt;
  /// limitations for array parameters like interest_ids[].
  ///
  /// interest_ids are appended as interest_ids[]=1&interest_ids[]=2 which is
  /// the PHP/Laravel array convention.
  String _buildCompanionsPath(
    Map<String, String> params,
    List<int>? interestIds,
  ) {
    final buffer = StringBuffer(ApiConstants.companions);
    final allParams = <String>[];

    params.forEach((k, v) {
      allParams.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
    });

    if (interestIds != null && interestIds.isNotEmpty) {
      for (final id in interestIds) {
        allParams.add('interest_ids%5B%5D=$id');
      }
    }

    if (allParams.isNotEmpty) {
      buffer.write('?${allParams.join('&')}');
    }

    return buffer.toString();
  }

  void dispose() => _client.dispose();
}
