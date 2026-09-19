import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/chat_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationDetailScreen  (Chat)
// ─────────────────────────────────────────────────────────────────────────────

class ConversationDetailScreen extends StatefulWidget {
  const ConversationDetailScreen({
    super.key,
    required this.conversation,
  });

  final ConversationModel conversation;

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen>
    with WidgetsBindingObserver {
  final _service = ChatService();
  final _authService = AuthService();
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  // Message state
  List<MessageModel> _messages = [];
  bool _initialLoading = true;
  bool _loadingOlder = false;
  bool _hasMoreOlder = true;
  int _currentPage = 1;
  String? _loadError;

  // Sending state
  bool _isSending = false;
  String? _sendError;

  // Auth user id (to distinguish sent/received)
  int? _authUserId;

  // Polling
  Timer? _pollTimer;
  bool _isPolling = false;
  bool _screenActive = true;

  static const _pollInterval = Duration(seconds: 8);
  static const _maxMessageLength = 5000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _init();
  }

  Future<void> _init() async {
    await _loadAuthUserId();
    await _loadMessages();
    _markRead();
    _startPolling();
  }

  /// Resolve the authenticated user's ID via [AuthService.getCurrentUser].
  ///
  /// Uses [GET /api/auth/me] which is already part of the existing architecture.
  /// This guarantees correct sent/received bubble alignment even when the first
  /// page of messages is entirely from the other participant.
  Future<void> _loadAuthUserId() async {
    try {
      final user = await _authService.getCurrentUser();
      _authUserId = user.id;
    } catch (_) {
      // Non-fatal — fallback to message-sender inference (_resolveAuthUserId)
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    _service.dispose();
    _authService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _screenActive) {
      _pollOnce(); // Catch up after app resume
    }
    _screenActive = state == AppLifecycleState.resumed;
  }

  // ── Scroll ──────────────────────────────────────────────────────────────────

  void _onScroll() {
    if (_loadingOlder || !_hasMoreOlder) return;
    // Load older messages when near the TOP
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 150) {
      _loadOlderMessages();
    }
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent);
      }
    });
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    final max = _scrollController.position.maxScrollExtent;
    return max - _scrollController.position.pixels < 120;
  }

  // ── Auth user resolution ──────────────────────────────────────────────────

  /// Determine authUserId from messages and the known other participant.
  void _resolveAuthUserId(List<MessageModel> messages) {
    if (_authUserId != null) return;
    final otherId = widget.conversation.otherParticipant?.id;
    for (final m in messages) {
      if (m.sender?.id != null && m.sender!.id != otherId) {
        _authUserId = m.sender!.id;
        return;
      }
    }
  }

  bool _isMyMessage(MessageModel msg) {
    if (_authUserId != null) return msg.sender?.id == _authUserId;
    // Fallback: if sender is the other participant, it's received.
    return msg.sender?.id != widget.conversation.otherParticipant?.id;
  }

  // ── Loading messages ──────────────────────────────────────────────────────

  Future<void> _loadMessages() async {
    setState(() {
      _initialLoading = true;
      _loadError = null;
      _currentPage = 1;
      _messages = [];
    });
    try {
      final result = await _service.getMessages(
        conversationId: widget.conversation.id,
        page: 1,
      );
      if (!mounted) return;
      // Backend returns newest-first → reverse so oldest at top.
      final msgs = result.items.reversed.toList();
      _resolveAuthUserId(msgs);
      setState(() {
        _messages = msgs;
        _hasMoreOlder = result.pagination.hasMore;
        _initialLoading = false;
      });
      _scrollToBottom();
    } on ForbiddenException {
      if (!mounted) return;
      setState(() {
        _loadError = 'You are not a participant of this conversation.';
        _initialLoading = false;
      });
    } on NotFoundException {
      if (!mounted) return;
      setState(() {
        _loadError = 'This conversation no longer exists.';
        _initialLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load messages.';
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingOlder || !_hasMoreOlder) return;
    setState(() => _loadingOlder = true);

    // Save current scroll offset to restore after prepending
    final prevMax = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    try {
      final nextPage = _currentPage + 1;
      final result = await _service.getMessages(
        conversationId: widget.conversation.id,
        page: nextPage,
      );
      if (!mounted) return;
      final older = result.items.reversed.toList(); // oldest-first
      // Prepend to list (de-duplicate by id)
      final existingIds = _messages.map((m) => m.id).toSet();
      final newOlder = older.where((m) => !existingIds.contains(m.id)).toList();
      setState(() {
        _messages = [...newOlder, ..._messages];
        _currentPage = nextPage;
        _hasMoreOlder = result.pagination.hasMore;
        _loadingOlder = false;
      });
      // Restore scroll position so user doesn't jump
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final newMax = _scrollController.position.maxScrollExtent;
        final targetOffset = newMax - prevMax;
        _scrollController.jumpTo(targetOffset.clamp(
            0.0, _scrollController.position.maxScrollExtent));
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingOlder = false);
      _showSnack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOlder = false);
    }
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (_screenActive) _pollOnce();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (_isPolling || _initialLoading) return;
    _isPolling = true;
    try {
      // Always fetch page 1 (newest messages)
      final result = await _service.getMessages(
        conversationId: widget.conversation.id,
        page: 1,
      );
      if (!mounted) {
        _isPolling = false;
        return;
      }
      final fetched = result.items.reversed.toList();
      _resolveAuthUserId(fetched);

      // Find genuinely new messages (higher id than we know about)
      final maxKnownId = _messages.isEmpty
          ? 0
          : _messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
      final newMsgs = fetched.where((m) => m.id > maxKnownId).toList();

      if (newMsgs.isNotEmpty && mounted) {
        final wasNearBottom = _isNearBottom;
        setState(() {
          _messages.addAll(newMsgs);
        });
        _markRead();
        if (wasNearBottom) {
          _scrollToBottom(animated: true);
        }
      }
    } catch (_) {
      // Silent failure — polling is best-effort
    } finally {
      _isPolling = false;
    }
  }

  // ── Mark as read ──────────────────────────────────────────────────────────

  Future<void> _markRead() async {
    try {
      await _service.markAsRead(conversationId: widget.conversation.id);
    } catch (_) {
      // Non-critical; ignore silently
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    if (text.length > _maxMessageLength) {
      _showSnack('Message is too long (max 5000 characters).', isError: true);
      return;
    }
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _sendError = null;
    });

    try {
      final msg = await _service.sendMessage(
        conversationId: widget.conversation.id,
        body: text,
      );
      if (!mounted) return;
      _inputController.clear();
      _resolveAuthUserId([msg]);
      setState(() {
        // Avoid duplicate if poll already picked it up
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
        _isSending = false;
      });
      _scrollToBottom(animated: true);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sendError = e.errors?['body']?.first ?? e.message;
      });
    } on ForbiddenException {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sendError = 'You are not allowed to send messages here.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sendError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sendError = 'Failed to send. Please try again.';
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final other = widget.conversation.otherParticipant;
    final name = other?.name ?? 'Chat';
    final photoUrl = _resolvePhotoUrl(other?.profilePhotoUrl);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(12, topPad + 10, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1628), Color(0xFF0F3460)],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 17),
                  ),
                ),
                const SizedBox(width: 12),
                _ChatAvatar(photoUrl: photoUrl, name: name, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: _buildMessageList(),
          ),

          // ── Send error banner ────────────────────────────────────────────
          if (_sendError != null)
            Container(
              width: double.infinity,
              color: AppColors.error.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sendError!,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppColors.error),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _sendError = null),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.error),
                  ),
                ],
              ),
            ),

          // ── Input bar ────────────────────────────────────────────────────
          _InputBar(
            controller: _inputController,
            focusNode: _focusNode,
            isSending: _isSending,
            onSend: _sendMessage,
            bottomPad: bottomPad,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return _ErrorBody(message: _loadError!, onRetry: _loadMessages);
    }

    if (_messages.isEmpty) {
      return _EmptyChat(
        name: widget.conversation.otherParticipant?.name ?? 'them',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingH, vertical: 12),
      itemCount: _messages.length + (_loadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (_loadingOlder && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final msgIndex = _loadingOlder ? index - 1 : index;
        final msg = _messages[msgIndex];
        return _MessageBubble(
          message: msg,
          isMe: _isMyMessage(msg),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final MessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final time = _formatTimestamp(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.body,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: isMe ? Colors.white : AppColors.textPrimaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textHintLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Bar
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
    required this.bottomPad,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;
  final double bottomPad;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, widget.bottomPad == 0 ? 10 : widget.bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                maxLength: 5000,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    null, // hide counter; validation handles max
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textHintLight,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) {
                  if (_hasText && !widget.isSending) widget.onSend();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: (_hasText && !widget.isSending) ? widget.onSend : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: (_hasText && !widget.isSending)
                      ? AppColors.primaryGradient
                      : [Colors.grey.shade300, Colors.grey.shade400],
                ),
              ),
              child: widget.isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.photoUrl,
    required this.name,
    required this.size,
  });

  final String? photoUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, _) =>
              _FallbackAvatar(initial: initial, size: size),
        ),
      );
    }
    return _FallbackAvatar(initial: initial, size: size);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initial, required this.size});
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.nunito(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_rounded,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Start the conversation!',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send $name a message below.',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 14, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo URL resolver (consistent with the rest of the app)
// ─────────────────────────────────────────────────────────────────────────────

String? _resolvePhotoUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  return null;
}
