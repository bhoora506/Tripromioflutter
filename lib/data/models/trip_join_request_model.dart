// ── Join Request Status ──────────────────────────────────────────────────────

/// Lifecycle statuses for a trip join request.
enum JoinRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,

  /// Fallback for any value the client does not recognise.
  unknown;

  /// Parse a backend string into a [JoinRequestStatus].
  ///
  /// Returns [JoinRequestStatus.unknown] for unrecognised values.
  static JoinRequestStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return JoinRequestStatus.pending;
      case 'approved':
        return JoinRequestStatus.approved;
      case 'rejected':
        return JoinRequestStatus.rejected;
      case 'cancelled':
        return JoinRequestStatus.cancelled;
      default:
        return JoinRequestStatus.unknown;
    }
  }

  /// Whether this status is terminal (cannot be actioned further).
  bool get isTerminal =>
      this == JoinRequestStatus.approved ||
      this == JoinRequestStatus.rejected ||
      this == JoinRequestStatus.cancelled;
}

// ── Join Request Requester ───────────────────────────────────────────────────

/// Lightweight requester embedded in a [TripJoinRequestModel].
///
/// Only contains `id` and `name` — mirrors the backend JoinRequestResource.
class JoinRequestRequester {
  const JoinRequestRequester({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory JoinRequestRequester.fromJson(Map<String, dynamic> json) {
    return JoinRequestRequester(
      id: _parseInt(json['id']),
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => 'JoinRequestRequester(id: $id, name: $name)';
}

// ── Trip Join Request Model ──────────────────────────────────────────────────

/// Represents a single join request as returned by the backend
/// `TripJoinRequestResource`.
///
/// Parsing is defensive:
///   • `requester` may be absent → [requester] is nullable.
///   • Unknown `status` values fall back to [JoinRequestStatus.unknown].
///   • `trip_id` / `id` fields are parsed safely via [_parseInt].
class TripJoinRequestModel {
  const TripJoinRequestModel({
    required this.id,
    required this.tripId,
    required this.status,
    this.requester,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int tripId;
  final JoinRequestStatus status;

  /// The user who submitted the request.
  ///
  /// May be `null` if the backend omits the relationship in some contexts.
  final JoinRequestRequester? requester;

  final String? createdAt;
  final String? updatedAt;

  factory TripJoinRequestModel.fromJson(Map<String, dynamic> json) {
    return TripJoinRequestModel(
      id: _parseInt(json['id']),
      tripId: _parseInt(json['trip_id']),
      status: JoinRequestStatus.fromString(json['status'] as String?),
      requester: json['requester'] != null
          ? JoinRequestRequester.fromJson(
              json['requester'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'status': status.name,
        'requester': requester?.toJson(),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// Returns a copy of this model with [status] updated.
  TripJoinRequestModel copyWith({JoinRequestStatus? status}) {
    return TripJoinRequestModel(
      id: id,
      tripId: tripId,
      status: status ?? this.status,
      requester: requester,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() =>
      'TripJoinRequestModel(id: $id, tripId: $tripId, status: ${status.name})';
}

// ── Shared safe parsers ──────────────────────────────────────────────────────

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is num) return value.toInt();
  return 0;
}
