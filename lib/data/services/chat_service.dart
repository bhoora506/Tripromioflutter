import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Service for all Chat / Conversation API calls.
///
/// Endpoints covered:
///   GET    /api/conversations                          → [getConversations]
///   POST   /api/conversations                          → [createConversation]
///   GET    /api/conversations/{id}/messages            → [getMessages]
///   POST   /api/conversations/{id}/messages            → [sendMessage]
///   POST   /api/conversations/{id}/read               → [markAsRead]
///
/// Uses the existing [ApiClient].
/// Throws [ApiException] subclasses on failure.
class ChatService {
  ChatService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ── GET /api/conversations ────────────────────────────────────────────────

  /// Fetch the authenticated user's paginated conversation list.
  /// Sorted by latest activity (backend handles ordering).
  Future<PaginatedConversationsModel> getConversations({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _client.get(
      ApiConstants.conversations,
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    return PaginatedConversationsModel.fromJson(response.dataAsMap);
  }

  // ── POST /api/conversations ───────────────────────────────────────────────

  /// Find or create a conversation with [recipientId].
  ///
  /// Backend returns the existing conversation if one already exists (idempotent).
  /// Throws [ConflictException] (409) if the connection is not accepted.
  /// Throws [NotFoundException] (404) if the recipient does not exist.
  Future<ConversationModel> createConversation({
    required int recipientId,
  }) async {
    final response = await _client.post(
      ApiConstants.conversations,
      body: {'recipient_id': recipientId},
    );
    final data = response.dataAsMap;
    // Backend wraps the conversation in a 'conversation' key.
    final convJson = data['conversation'] as Map<String, dynamic>?;
    if (convJson != null) {
      return ConversationModel.fromJson(convJson);
    }
    // Fallback: the data map itself is the conversation.
    return ConversationModel.fromJson(data);
  }

  // ── GET /api/conversations/{id}/messages ──────────────────────────────────

  /// Fetch a specific conversation by ID.
  Future<ConversationModel> getConversation(int conversationId) async {
    final response = await _client.get('${ApiConstants.conversations}/$conversationId');
    final data = response.dataAsMap;
    final convJson = data['conversation'] as Map<String, dynamic>?;
    if (convJson != null) {
      return ConversationModel.fromJson(convJson);
    }
    return ConversationModel.fromJson(data);
  }

  /// Fetch paginated message history for [conversationId].
  ///
  /// Backend returns newest-first. The UI displays them reversed (oldest at top).
  Future<PaginatedMessagesModel> getMessages({
    required int conversationId,
    int page = 1,
    int perPage = 30,
  }) async {
    final response = await _client.get(
      ApiConstants.conversationMessages(conversationId),
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    return PaginatedMessagesModel.fromJson(response.dataAsMap);
  }

  // ── POST /api/conversations/{id}/messages ─────────────────────────────────

  /// Send a text message in [conversationId].
  ///
  /// [body] must be non-blank and ≤ 5000 characters.
  /// The caller should validate before calling this.
  ///
  /// Returns the created [MessageModel].
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    final response = await _client.post(
      ApiConstants.conversationMessages(conversationId),
      body: {'body': body},
    );
    final data = response.dataAsMap;
    final msgJson = data['message'] as Map<String, dynamic>?;
    if (msgJson != null) {
      return MessageModel.fromJson(msgJson);
    }
    return MessageModel.fromJson(data);
  }

  // ── POST /api/conversations/{id}/read ────────────────────────────────────

  /// Mark unread messages from the other participant as read.
  /// Idempotent — safe to call multiple times.
  Future<void> markAsRead({required int conversationId}) async {
    await _client.post(ApiConstants.conversationRead(conversationId));
  }

  void dispose() => _client.dispose();
}
