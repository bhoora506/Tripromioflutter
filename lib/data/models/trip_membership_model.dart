import 'trip_join_request_model.dart';

class TripMembershipModel {
  final bool isOwner;
  final bool isMember;
  final String? role;
  final String? status;
  final DateTime? joinedAt;
  final JoinRequestStatus? joinRequestStatus;
  final int? joinRequestId;

  const TripMembershipModel({
    required this.isOwner,
    required this.isMember,
    this.role,
    this.status,
    this.joinedAt,
    this.joinRequestStatus,
    this.joinRequestId,
  });

  factory TripMembershipModel.fromJson(Map<String, dynamic> json) {
    JoinRequestStatus? requestStatus;
    if (json['join_request_status'] != null) {
      final statusStr = json['join_request_status'] as String;
      requestStatus = JoinRequestStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => JoinRequestStatus.unknown,
      );
    }

    DateTime? parsedJoinedAt;
    if (json['joined_at'] != null) {
      parsedJoinedAt = DateTime.tryParse(json['joined_at'].toString());
    }

    return TripMembershipModel(
      isOwner: _parseBool(json['is_owner']),
      isMember: _parseBool(json['is_member']),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      joinedAt: parsedJoinedAt,
      joinRequestStatus: requestStatus,
      joinRequestId: json['join_request_id'] != null
          ? _parseInt(json['join_request_id'])
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}
