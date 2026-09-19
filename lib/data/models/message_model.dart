import 'conversation_model.dart' show ChatParticipantModel;
import 'trip_model.dart' show PaginationModel;

// ── Message Model ─────────────────────────────────────────────────────────────

/// Represents a Message as returned by the backend MessageResource.
///
/// Maps to: GET /api/conversations/{id}/messages
///          POST /api/conversations/{id}/messages
///
/// Backend contract (from MessageResource):
///   id, conversation_id, sender (id, name, profile_photo_url),
///   body, read_at, created_at, updated_at
class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    this.sender,
    required this.body,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int conversationId;
  final ChatParticipantModel? sender;
  final String body;
  final String? readAt;
  final String? createdAt;
  final String? updatedAt;

  bool get isRead => readAt != null;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: _parseInt(json['id']),
      conversationId: _parseInt(json['conversation_id']),
      sender: json['sender'] is Map<String, dynamic>
          ? ChatParticipantModel.fromJson(
              json['sender'] as Map<String, dynamic>)
          : null,
      body: json['body'] as String? ?? '',
      readAt: json['read_at']?.toString(),
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

  @override
  String toString() => 'MessageModel(id: $id, conversationId: $conversationId)';
}

// ── Paginated Messages ────────────────────────────────────────────────────────

/// Wraps a paginated list of [MessageModel] with [PaginationModel].
///
/// Note: backend returns newest-first; the screen reverses display order.
class PaginatedMessagesModel {
  const PaginatedMessagesModel({
    required this.items,
    required this.pagination,
  });

  final List<MessageModel> items;
  final PaginationModel pagination;

  factory PaginatedMessagesModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final paginationJson =
        json['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return PaginatedMessagesModel(
      items: itemsList
          .map((i) => MessageModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(paginationJson),
    );
  }

  @override
  String toString() => 'PaginatedMessagesModel(${items.length} items)';
}
