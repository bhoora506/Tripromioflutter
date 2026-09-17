import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/connection_request_model.dart';

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
