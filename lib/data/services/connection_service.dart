import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/companion_model.dart' show PaginatedCompanionsModel;
import '../models/connection_request_model.dart';
import '../models/trip_model.dart' show PaginationModel;

// ── Paginated Connections Response ────────────────────────────────────────────

/// Wraps a paginated list of [ConnectionRequestModel] items with [PaginationModel].
/// Matches GET /api/connections/received and GET /api/connections/sent envelopes.
class PaginatedConnectionsModel {
  const PaginatedConnectionsModel({
    required this.items,
    required this.pagination,
  });

  final List<ConnectionRequestModel> items;
  final PaginationModel pagination;

  factory PaginatedConnectionsModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final paginationJson =
        json['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return PaginatedConnectionsModel(
      items: itemsList
          .map((i) => ConnectionRequestModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(paginationJson),
    );
  }
}

/// Service for connection request API calls (F2 endpoints).
///
/// Endpoints covered:
///   POST /api/connections                           → [sendConnectionRequest]
///   POST /api/connections/{id}/accept               → [acceptConnectionRequest]
///   POST /api/connections/{id}/reject               → [rejectConnectionRequest]
///   POST /api/connections/{id}/cancel               → [cancelConnectionRequest]
///
/// Throws [ApiException] subclasses on failure, including:
///   [ConflictException] (409) when a request already exists.
class ConnectionService {
  ConnectionService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ── GET /api/connections ──────────────────────────────────────────────────

  /// Fetch paginated accepted connections.
  Future<PaginatedCompanionsModel> getMyConnections({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _client.get(
      ApiConstants.connections,
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    return PaginatedCompanionsModel.fromJson(response.dataAsMap);
  }

  // ── GET /api/connections/received ────────────────────────────────────────────

  /// Fetch paginated connection requests received by the authenticated user.
  Future<PaginatedConnectionsModel> getReceivedRequests({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _client.get(
      ApiConstants.connectionsReceived,
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    return PaginatedConnectionsModel.fromJson(response.dataAsMap);
  }

  // ── GET /api/connections/sent ─────────────────────────────────────────────

  /// Fetch paginated connection requests sent by the authenticated user.
  Future<PaginatedConnectionsModel> getSentRequests({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _client.get(
      ApiConstants.connectionsSent,
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    return PaginatedConnectionsModel.fromJson(response.dataAsMap);
  }

  // ── POST /api/connections ─────────────────────────────────────────────────

  /// Send a connection request to [recipientId].
  ///
  /// Returns the created [ConnectionRequestModel].
  ///
  /// Throws [ConflictException] (409) if a pending/accepted request already
  /// exists between the two users. The caller must handle this gracefully.
  Future<ConnectionRequestModel> sendConnectionRequest(int recipientId) async {
    final response = await _client.post(
      ApiConstants.connections,
      body: {'recipient_id': recipientId},
    );

    final data = response.dataAsMap;
    final reqJson = data['connection_request'] as Map<String, dynamic>?;
    if (reqJson == null) {
      return ConnectionRequestModel.fromJson(data);
    }
    return ConnectionRequestModel.fromJson(reqJson);
  }

  // ── POST /api/connections/{id}/accept ─────────────────────────────────────

  Future<ConnectionRequestModel> acceptConnectionRequest(int id) async {
    final response = await _client.post(
        ApiConstants.connectionAction(id, 'accept'));
    final data = response.dataAsMap;
    final reqJson = data['connection_request'] as Map<String, dynamic>?;
    if (reqJson == null) return ConnectionRequestModel.fromJson(data);
    return ConnectionRequestModel.fromJson(reqJson);
  }

  // ── POST /api/connections/{id}/reject ─────────────────────────────────────

  Future<ConnectionRequestModel> rejectConnectionRequest(int id) async {
    final response = await _client.post(
        ApiConstants.connectionAction(id, 'reject'));
    final data = response.dataAsMap;
    final reqJson = data['connection_request'] as Map<String, dynamic>?;
    if (reqJson == null) return ConnectionRequestModel.fromJson(data);
    return ConnectionRequestModel.fromJson(reqJson);
  }

  // ── POST /api/connections/{id}/cancel ─────────────────────────────────────

  Future<void> cancelConnectionRequest(int id) async {
    await _client.post(ApiConstants.connectionAction(id, 'cancel'));
  }

  void dispose() => _client.dispose();
}
