import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/connection_request_model.dart';
import '../../../data/services/connection_service.dart';
import '../profile/profile_screen.dart' show resolvePhotoUrl;

// ─────────────────────────────────────────────────────────────────────────────
// ConnectionRequestsScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Displays received and sent connection requests in two tabs.
///
/// Received tab: shows Accept / Reject actions for pending requests.
/// Sent tab: shows Cancel action for pending sent requests.
///
/// Pagination is supported (backend returns items + pagination envelope).
class ConnectionRequestsScreen extends StatefulWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  State<ConnectionRequestsScreen> createState() =>
      _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = ConnectionService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              AppConstants.screenPaddingH,
              topPad + AppConstants.spacingMd,
              AppConstants.screenPaddingH,
              0,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1628), Color(0xFF0F3460)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppConstants.radiusXl),
                bottomRight: Radius.circular(AppConstants.radiusXl),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                    const SizedBox(width: AppConstants.spacingMd),
                    Text(
                      'Connection Requests',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMd),
                // Tab bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryLight,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
                  labelStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Received'),
                    Tab(text: 'Sent'),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab Views ─────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ReceivedTab(service: _service),
                _SentTab(service: _service),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Received Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ReceivedTab extends StatefulWidget {
  const _ReceivedTab({required this.service});
  final ConnectionService service;

  @override
  State<_ReceivedTab> createState() => _ReceivedTabState();
}

class _ReceivedTabState extends State<_ReceivedTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  List<ConnectionRequestModel> _requests = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _paginationError;

  // Track per-item action loading to avoid freezing the whole screen
  final Set<int> _pendingActions = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _paginationError = null;
      _currentPage = 1;
      _requests = [];
    });

    try {
      final result = await widget.service.getReceivedRequests(page: 1);
      if (!mounted) return;
      setState(() {
        _requests = result.items;
        _hasMore = result.pagination.hasMore;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _error = 'Session expired. Please log in again.';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });
    try {
      final nextPage = _currentPage + 1;
      final result =
          await widget.service.getReceivedRequests(page: nextPage);
      if (!mounted) return;
      setState(() {
        _requests.addAll(result.items);
        _currentPage = nextPage;
        _hasMore = result.pagination.hasMore;
        _loadingMore = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = e.message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = 'Failed to load more. Tap to retry.';
      });
    }
  }

  Future<void> _accept(ConnectionRequestModel req) async {
    if (_pendingActions.contains(req.id)) return;
    setState(() => _pendingActions.add(req.id));

    try {
      final updated = await widget.service.acceptConnectionRequest(req.id);
      if (!mounted) return;
      setState(() {
        _pendingActions.remove(req.id);
        // Replace item with updated status so Accept/Reject buttons disappear
        final idx = _requests.indexWhere((r) => r.id == req.id);
        if (idx != -1) _requests[idx] = updated;
      });
      _showSnack('Connection request accepted!', success: true);
    } on ConflictException catch (e) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack(e.message);
      await _load(); // Refresh as state may have changed externally
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack(e.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack('Failed to accept request. Try again.');
    }
  }

  Future<void> _reject(ConnectionRequestModel req) async {
    if (_pendingActions.contains(req.id)) return;
    setState(() => _pendingActions.add(req.id));

    try {
      final updated = await widget.service.rejectConnectionRequest(req.id);
      if (!mounted) return;
      setState(() {
        _pendingActions.remove(req.id);
        final idx = _requests.indexWhere((r) => r.id == req.id);
        if (idx != -1) _requests[idx] = updated;
      });
      _showSnack('Connection request rejected.', success: true);
    } on ConflictException catch (e) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack(e.message);
      await _load();
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack(e.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack('Failed to reject request. Try again.');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    if (_requests.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_rounded,
        message: 'No connection requests yet.',
        hint: "When someone wants to connect with you, it'll appear here.",
        onRefresh: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingH,
          vertical: AppConstants.spacingMd,
        ),
        itemCount:
            _requests.length + (_hasMore || _paginationError != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _requests.length) {
            if (_paginationError != null) {
              return _PaginationError(
                message: _paginationError!,
                onRetry: _loadMore,
              );
            }
            return _PaginationLoader(isLoading: _loadingMore);
          }

          final req = _requests[index];
          final isActing = _pendingActions.contains(req.id);
          final isPending = req.status == 'pending';

          return _ReceivedRequestCard(
            request: req,
            isActing: isActing,
            onAccept: isPending ? () => _accept(req) : null,
            onReject: isPending ? () => _reject(req) : null,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sent Tab
// ─────────────────────────────────────────────────────────────────────────────

class _SentTab extends StatefulWidget {
  const _SentTab({required this.service});
  final ConnectionService service;

  @override
  State<_SentTab> createState() => _SentTabState();
}

class _SentTabState extends State<_SentTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  List<ConnectionRequestModel> _requests = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _paginationError;

  final Set<int> _pendingActions = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _paginationError = null;
      _currentPage = 1;
      _requests = [];
    });

    try {
      final result = await widget.service.getSentRequests(page: 1);
      if (!mounted) return;
      setState(() {
        _requests = result.items;
        _hasMore = result.pagination.hasMore;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _error = 'Session expired. Please log in again.';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });
    try {
      final nextPage = _currentPage + 1;
      final result = await widget.service.getSentRequests(page: nextPage);
      if (!mounted) return;
      setState(() {
        _requests.addAll(result.items);
        _currentPage = nextPage;
        _hasMore = result.pagination.hasMore;
        _loadingMore = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = e.message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = 'Failed to load more. Tap to retry.';
      });
    }
  }

  Future<void> _cancel(ConnectionRequestModel req) async {
    if (_pendingActions.contains(req.id)) return;
    setState(() => _pendingActions.add(req.id));

    try {
      await widget.service.cancelConnectionRequest(req.id);
      if (!mounted) return;
      setState(() {
        _pendingActions.remove(req.id);
        // Remove from list immediately (cancelled requests disappear from pending view)
        _requests.removeWhere((r) => r.id == req.id);
      });
      _showSnack('Connection request cancelled.', success: true);
    } on ConflictException catch (e) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack(e.message);
      await _load();
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack(e.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingActions.remove(req.id));
      _showSnack('Failed to cancel request. Try again.');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    if (_requests.isEmpty) {
      return _EmptyState(
        icon: Icons.send_rounded,
        message: 'No sent requests.',
        hint: 'Requests you send from Companion Discovery will appear here.',
        onRefresh: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingH,
          vertical: AppConstants.spacingMd,
        ),
        itemCount:
            _requests.length + (_hasMore || _paginationError != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _requests.length) {
            if (_paginationError != null) {
              return _PaginationError(
                message: _paginationError!,
                onRetry: _loadMore,
              );
            }
            return _PaginationLoader(isLoading: _loadingMore);
          }

          final req = _requests[index];
          final isActing = _pendingActions.contains(req.id);
          final isPending = req.status == 'pending';

          return _SentRequestCard(
            request: req,
            isActing: isActing,
            onCancel: isPending ? () => _cancel(req) : null,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Received Request Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReceivedRequestCard extends StatelessWidget {
  const _ReceivedRequestCard({
    required this.request,
    required this.isActing,
    this.onAccept,
    this.onReject,
  });

  final ConnectionRequestModel request;
  final bool isActing;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final user = request.requester;
    final name = user?.name ?? 'Unknown User';
    final photoUrl = resolvePhotoUrl(user?.profilePhotoUrl);
    final isPending = request.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                _Avatar(photoUrl: photoUrl, name: name, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _StatusBadge(status: request.status),
                    ],
                  ),
                ),
              ],
            ),

            // Actions for pending requests
            if (isPending) ...[
              const SizedBox(height: 14),
              if (isActing)
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Accept',
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        onTap: onAccept,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        color: AppColors.error,
                        onTap: onReject,
                        outlined: true,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sent Request Card
// ─────────────────────────────────────────────────────────────────────────────

class _SentRequestCard extends StatelessWidget {
  const _SentRequestCard({
    required this.request,
    required this.isActing,
    this.onCancel,
  });

  final ConnectionRequestModel request;
  final bool isActing;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final user = request.recipient;
    final name = user?.name ?? 'Unknown User';
    final photoUrl = resolvePhotoUrl(user?.profilePhotoUrl);
    final isPending = request.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Avatar(photoUrl: photoUrl, name: name, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: request.status),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isPending)
              isActing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusFull),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
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
          errorBuilder: (context, error, stackTrace) =>
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  static const Map<String, _StatusStyle> _styles = {
    'pending': _StatusStyle(
        label: 'Pending', color: Color(0xFFF59E0B), bg: Color(0xFFFEF3C7)),
    'accepted': _StatusStyle(
        label: 'Accepted', color: Color(0xFF10B981), bg: Color(0xFFD1FAE5)),
    'rejected': _StatusStyle(
        label: 'Rejected', color: Color(0xFFEF4444), bg: Color(0xFFFEE2E2)),
    'cancelled': _StatusStyle(
        label: 'Cancelled',
        color: Color(0xFF6B7280),
        bg: Color(0xFFF3F4F6)),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[status] ??
        _StatusStyle(
          label: status[0].toUpperCase() + status.substring(1),
          color: AppColors.textSecondaryLight,
          bg: AppColors.borderLight,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        style.label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: style.color,
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle(
      {required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppColors.textSecondaryLight),
            ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.hint,
    required this.onRefresh,
  });

  final IconData icon;
  final String message;
  final String hint;
  final VoidCallback onRefresh;

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
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationLoader extends StatelessWidget {
  const _PaginationLoader({required this.isLoading});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _PaginationError extends StatelessWidget {
  const _PaginationError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
