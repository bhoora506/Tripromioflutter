import 'trip_model.dart' show PaginationModel;

// ── Chat Participant ──────────────────────────────────────────────────────────

/// Minimal participant info embedded in a [ConversationModel] or [MessageModel].
///
/// Privacy rules (enforced by backend):
///   - email is NEVER present
///   - only id, name, and profile_photo_url are exposed
class ChatParticipantModel {
  const ChatParticipantModel({
    required this.id,
    required this.name,
    this.profilePhotoUrl,
  });

  final int id;
  final String name;
  final String? profilePhotoUrl;

  factory ChatParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChatParticipantModel(
      id: _parseInt(json['id']),
      name: json['name'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
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

// ── Latest Message Preview ───────────────────────────────────────────────────

/// Minimal message preview included in [ConversationModel].
class LatestMessagePreview {
  const LatestMessagePreview({
    required this.id,
    required this.body,
    required this.senderId,
    this.createdAt,
  });

  final int id;
  final String body;
  final int senderId;
  final String? createdAt;

  factory LatestMessagePreview.fromJson(Map<String, dynamic> json) {
    return LatestMessagePreview(
      id: _parseInt(json['id']),
      body: json['body'] as String? ?? '',
      senderId: _parseInt(json['sender_id']),
      createdAt: json['created_at']?.toString(),
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

// ── Conversation Model ────────────────────────────────────────────────────────

/// Represents a Conversation as returned by the backend ConversationResource.
///
/// Maps to: GET /api/conversations  and  POST /api/conversations
///
/// Backend contract (from ConversationResource):
///   id, other_participant, latest_message, unread_count, created_at, updated_at
class ConversationModel {
  const ConversationModel({
    required this.id,
    this.otherParticipant,
    this.latestMessage,
    required this.unreadCount,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final ChatParticipantModel? otherParticipant;
  final LatestMessagePreview? latestMessage;
  final int unreadCount;
  final String? createdAt;
  final String? updatedAt;

  bool get hasUnread => unreadCount > 0;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: _parseInt(json['id']),
      otherParticipant: json['other_participant'] is Map<String, dynamic>
          ? ChatParticipantModel.fromJson(
              json['other_participant'] as Map<String, dynamic>)
          : null,
      latestMessage: json['latest_message'] is Map<String, dynamic>
          ? LatestMessagePreview.fromJson(
              json['latest_message'] as Map<String, dynamic>)
          : null,
      unreadCount: _parseInt(json['unread_count']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  /// Return a copy with updated unread count (e.g., after marking as read).
  ConversationModel withUnreadCount(int count) {
    return ConversationModel(
      id: id,
      otherParticipant: otherParticipant,
      latestMessage: latestMessage,
      unreadCount: count,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  String toString() => 'ConversationModel(id: $id, unreadCount: $unreadCount)';
}

// ── Paginated Conversations ───────────────────────────────────────────────────

/// Wraps a paginated list of [ConversationModel] with [PaginationModel].
class PaginatedConversationsModel {
  const PaginatedConversationsModel({
    required this.items,
    required this.pagination,
  });

  final List<ConversationModel> items;
  final PaginationModel pagination;

  factory PaginatedConversationsModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final paginationJson =
        json['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return PaginatedConversationsModel(
      items: itemsList
          .map((i) => ConversationModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(paginationJson),
    );
  }

  @override
  String toString() =>
      'PaginatedConversationsModel(${items.length} items)';
}
