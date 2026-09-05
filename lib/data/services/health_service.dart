import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

/// Service for verifying Flutter → Laravel connectivity.
///
/// This is intentionally minimal — it calls the public `/health` endpoint
/// and returns a [HealthResult] so callers can display the status cleanly.
///
/// Example:
/// ```dart
/// final service = HealthService();
/// final result = await service.checkHealth();
/// if (result.isHealthy) { ... }
/// ```
class HealthService {
  HealthService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Calls `GET /health` and returns a [HealthResult].
  ///
  /// Never throws – errors are captured inside [HealthResult].
  Future<HealthResult> checkHealth() async {
    try {
      final response = await _client.get(ApiConstants.health);
      final status = response.dataAsMap['status'] as String? ?? 'unknown';
      return HealthResult(
        isHealthy: response.success && status == 'ok',
        message: response.message,
        status: status,
      );
    } on NetworkException catch (e) {
      return HealthResult(
        isHealthy: false,
        message: e.message,
        status: 'unreachable',
      );
    } on ApiException catch (e) {
      return HealthResult(
        isHealthy: false,
        message: e.message,
        status: 'error',
      );
    } catch (e) {
      return HealthResult(
        isHealthy: false,
        message: 'Unexpected error: $e',
        status: 'error',
      );
    }
  }

  void dispose() => _client.dispose();
}

/// Result object returned by [HealthService.checkHealth].
class HealthResult {
  const HealthResult({
    required this.isHealthy,
    required this.message,
    required this.status,
  });

  /// `true` when the backend responded with `{ "data": { "status": "ok" } }`.
  final bool isHealthy;

  /// Human-readable message from the backend, or an error description.
  final String message;

  /// Raw `status` string from the backend data payload.
  final String status;

  @override
  String toString() => 'HealthResult(isHealthy: $isHealthy, status: $status, message: $message)';
}
