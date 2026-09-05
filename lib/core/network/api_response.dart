/// Represents the standard Tripromio backend response envelope.
///
/// Every successful 2xx response is decoded into this object.
///
/// ```json
/// { "success": true, "message": "OK", "data": { ... } }
/// ```
class ApiResponse {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;

  /// Raw `data` payload.  May be a Map, List, or null depending on endpoint.
  final dynamic data;

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'],
    );
  }

  /// Convenience: cast [data] to a [Map] (for single-resource endpoints).
  Map<String, dynamic> get dataAsMap =>
      (data as Map<String, dynamic>?) ?? <String, dynamic>{};

  /// Convenience: cast [data] to a [List] (for collection endpoints).
  List<dynamic> get dataAsList => (data as List<dynamic>?) ?? <dynamic>[];

  @override
  String toString() => 'ApiResponse(success: $success, message: $message)';
}
