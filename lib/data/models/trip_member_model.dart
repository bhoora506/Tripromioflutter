class TripMemberModel {
  final int id;
  final int userId;
  final String userName;
  final String role;
  final String status;
  final DateTime? joinedAt;

  const TripMemberModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  factory TripMemberModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};

    DateTime? parsedJoinedAt;
    if (json['joined_at'] != null) {
      parsedJoinedAt = DateTime.tryParse(json['joined_at'].toString());
    }

    return TripMemberModel(
      id: _parseInt(json['id']),
      userId: _parseInt(userJson['id']),
      userName: userJson['name']?.toString() ?? 'Unknown User',
      role: json['role']?.toString() ?? 'member',
      status: json['status']?.toString() ?? 'unknown',
      joinedAt: parsedJoinedAt,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}
