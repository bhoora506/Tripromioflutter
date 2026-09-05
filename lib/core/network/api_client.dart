import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';

/// Central HTTP client for all Tripromio API calls.
///
/// Responsibilities:
///   • Builds the full URL from [ApiConstants.baseUrl] + path.
///   • Injects `Accept: application/json` on every request.
///   • Injects `Content-Type: application/json` for JSON bodies.
///   • Attaches `Authorization: Bearer <token>` when a token exists.
///   • Decodes the standard `{ success, message, data }` envelope.
///   • Throws typed [ApiException] subclasses for every error condition.
///
/// Do NOT call this directly from the UI — use a dedicated service class
/// (e.g., [HealthService], [AuthService]) that wraps [ApiClient].
class ApiClient {
  ApiClient({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _httpClient = http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _httpClient;

  // ── Public HTTP methods ───────────────────────────────────────────────────

  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final headers = await _buildHeaders();
    try {
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(ApiConstants.receiveTimeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Request failed: ${e.message}');
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders(withContentType: true);
    try {
      final response = await _httpClient
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConstants.receiveTimeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Request failed: ${e.message}');
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders(withContentType: true);
    try {
      final response = await _httpClient
          .put(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConstants.receiveTimeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Request failed: ${e.message}');
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  Future<ApiResponse> delete(String path) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders();
    try {
      final response = await _httpClient
          .delete(uri, headers: headers)
          .timeout(ApiConstants.receiveTimeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Request failed: ${e.message}');
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    final fullUrl = '${ApiConstants.baseUrl}$path';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      });
    }
    return uri;
  }

  Future<Map<String, String>> _buildHeaders({bool withContentType = false}) async {
    final headers = <String, String>{
      ApiConstants.headerAccept: ApiConstants.mimeJson,
    };

    if (withContentType) {
      headers[ApiConstants.headerContentType] = ApiConstants.mimeJson;
    }

    // Only attach Authorization when a token is actually stored.
    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers[ApiConstants.headerAuthorization] = 'Bearer $token';
    }

    return headers;
  }

  ApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // 204 No Content – no body to decode.
    if (statusCode == 204) {
      return const ApiResponse(success: true, message: 'No content');
    }

    // Attempt to decode JSON body.
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Non-JSON body (shouldn't happen with a well-behaved Laravel backend).
      throw ServerException('Invalid response format (status $statusCode)');
    }

    // 2xx – success envelope.
    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse.fromJson(json);
    }

    // Extract error message from the envelope.
    final message = json['message'] as String? ?? 'Unknown error';

    // Parse optional field-level validation errors.
    Map<String, List<String>>? fieldErrors;
    if (json['errors'] is Map) {
      fieldErrors = (json['errors'] as Map).map(
        (k, v) => MapEntry(
          k.toString(),
          (v as List).map((e) => e.toString()).toList(),
        ),
      );
    }

    switch (statusCode) {
      case 400:
        throw BadRequestException(message, errors: fieldErrors);
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 409:
        throw ConflictException(message);
      case 422:
        throw ValidationException(message, errors: fieldErrors);
      case 429:
        throw TooManyRequestsException(message);
      default:
        if (statusCode >= 500) throw ServerException(message);
        throw ApiException(message: message, statusCode: statusCode);
    }
  }

  /// Release resources.  Call when the client is no longer needed.
  void dispose() => _httpClient.close();
}
