/// Represents a connection request as returned by the F2 API.
///
/// Privacy rules (enforced by backend, mirrored here):
///   - email is NEVER exposed for requester or recipient
///   - only id, name, and profile_photo_url are shown per user
class ConnectionRequestModel {
  const ConnectionRequestModel({
    required this.id,
    required this.status,
    this.requester,
    this.recipient,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String status;
  final ConnectionUserModel? requester;
  final ConnectionUserModel? recipient;
  final String? createdAt;
  final String? updatedAt;

  factory ConnectionRequestModel.fromJson(Map<String, dynamic> json) {
    return ConnectionRequestModel(
      id: _parseInt(json['id']),
      status: json['status'] as String? ?? 'pending',
      requester: json['requester'] is Map<String, dynamic>
          ? ConnectionUserModel.fromJson(
              json['requester'] as Map<String, dynamic>)
          : null,
      recipient: json['recipient'] is Map<String, dynamic>
          ? ConnectionUserModel.fromJson(
              json['recipient'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }
}

/// Minimal user info returned inside a connection request.
class ConnectionUserModel {
  const ConnectionUserModel({
    required this.id,
    required this.name,
    this.profilePhotoUrl,
  });

  final int id;
  final String name;
  final String? profilePhotoUrl;

  factory ConnectionUserModel.fromJson(Map<String, dynamic> json) {
    return ConnectionUserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }
}
