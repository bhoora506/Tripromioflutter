import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_join_request_model.dart';
import '../../../data/services/trip_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TripJoinRequestsScreen — owner-only join request management
// ─────────────────────────────────────────────────────────────────────────────

class TripJoinRequestsScreen extends StatefulWidget {
  const TripJoinRequestsScreen({super.key});

  @override
  State<TripJoinRequestsScreen> createState() => _TripJoinRequestsScreenState();
}

class _TripJoinRequestsScreenState extends State<TripJoinRequestsScreen> {
  final _tripService = TripService();

  int? _tripId;
  List<TripJoinRequestModel> _requests = [];
  bool _loading = true;
  String? _errorMessage;

  // Per-request action-in-progress flags: key = joinRequestId
  final Map<int, bool> _actionInProgress = {};

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _tripId = args;
        _load();
      } else {
        setState(() {
          _errorMessage = 'No trip ID provided.';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tripService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_tripId == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final requests = await _tripService.getJoinRequests(_tripId!);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } on ForbiddenException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'You are not authorised to view join requests for this trip.';
        _loading = false;
      });
    } on NotFoundException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Trip not found.';
        _loading = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No internet connection. Please retry.';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
        _loading = false;
      });
    }
  }

  // ── Approve ───────────────────────────────────────────────────────────────

  Future<void> _approve(TripJoinRequestModel request) async {
    if (_actionInProgress[request.id] == true || _tripId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Request?'),
        content: Text(
          'Approve ${request.requester?.name ?? 'this user'} to join the trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress[request.id] = true);
    try {
      final updated = await _tripService.approveJoinRequest(_tripId!, request.id);
      if (!mounted) return;
      _replaceRequest(updated);
      _showSnack('Request approved!', isSuccess: true);
    } on ConflictException catch (e) {
      if (mounted) {
        _showSnack(e.message);
        _load(); // refresh list — trip may now be full
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _actionInProgress.remove(request.id));
    }
  }

  // ── Reject ────────────────────────────────────────────────────────────────

  Future<void> _reject(TripJoinRequestModel request) async {
    if (_actionInProgress[request.id] == true || _tripId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request?'),
        content: Text(
          'Reject ${request.requester?.name ?? 'this user'}\'s join request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reject',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress[request.id] = true);
    try {
      final updated = await _tripService.rejectJoinRequest(_tripId!, request.id);
      if (!mounted) return;
      _replaceRequest(updated);
      _showSnack('Request rejected.');
    } on ConflictException catch (e) {
      if (mounted) {
        _showSnack(e.message);
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _actionInProgress.remove(request.id));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _replaceRequest(TripJoinRequestModel updated) {
    setState(() {
      _requests = _requests
          .map((r) => r.id == updated.id ? updated : r)
          .toList();
    });
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(AppConstants.screenPaddingH),
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimaryLight),
        ),
        title: Text(
          'Join Requests',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded,
                size: 20, color: AppColors.primary),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorView(message: _errorMessage!, onRetry: _load);
    }

    // Filter to only pending for the main actionable list;
    // show terminal entries below as a secondary section.
    final pending =
        _requests.where((r) => r.status == JoinRequestStatus.pending).toList();
    final others =
        _requests.where((r) => r.status != JoinRequestStatus.pending).toList();

    if (_requests.isEmpty) {
      return _EmptyView(onRefresh: _load);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppConstants.screenPaddingH,
          AppConstants.spacingMd,
          AppConstants.screenPaddingH,
          MediaQuery.paddingOf(context).bottom + AppConstants.spacingLg,
        ),
        children: [
          if (pending.isNotEmpty) ...[
            _SectionHeader(
              label: 'Pending (${pending.length})',
              color: AppColors.warning,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            ...pending.map(
              (r) => _RequestCard(
                request: r,
                actionInProgress: _actionInProgress[r.id] == true,
                onApprove: () => _approve(r),
                onReject: () => _reject(r),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
          ],
          if (others.isNotEmpty) ...[
            _SectionHeader(
              label: 'Other Requests (${others.length})',
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            ...others.map(
              (r) => _RequestCard(
                request: r,
                actionInProgress: false,
                onApprove: null,
                onReject: null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.actionInProgress,
    required this.onApprove,
    required this.onReject,
  });

  final TripJoinRequestModel request;
  final bool actionInProgress;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final name = request.requester?.name ?? 'Unknown User';
    final isPending = request.status == JoinRequestStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              _Initials(name: name, seed: request.requester?.id ?? 0),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Requested to join',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),

          // Action buttons — only for pending requests
          if (isPending && (onApprove != null || onReject != null)) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: actionInProgress ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5)),
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd)),
                      textStyle: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: actionInProgress ? null : onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd)),
                      textStyle: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: actionInProgress
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Avatar initials ───────────────────────────────────────────────────────────

const _kAvatarColors = [
  [Color(0xFF5B6CF8), Color(0xFF9B7CF8)],
  [Color(0xFFF85B6C), Color(0xFFF87C5B)],
  [Color(0xFF3DAF8A), Color(0xFF5BDDF8)],
  [Color(0xFFF8D45B), Color(0xFFF89F5B)],
  [Color(0xFF5BB8F8), Color(0xFF5B6CF8)],
];

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.seed});
  final String name;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final idx = seed % _kAvatarColors.length;
    final colors = _kAvatarColors[idx];
    final initials =
        name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final JoinRequestStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case JoinRequestStatus.pending:
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        label = 'Pending';
      case JoinRequestStatus.approved:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        label = 'Approved';
      case JoinRequestStatus.rejected:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        label = 'Rejected';
      case JoinRequestStatus.cancelled:
        bg = AppColors.textSecondaryLight.withValues(alpha: 0.12);
        fg = AppColors.textSecondaryLight;
        label = 'Cancelled';
      default:
        bg = AppColors.textSecondaryLight.withValues(alpha: 0.12);
        fg = AppColors.textSecondaryLight;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded,
                size: 56, color: AppColors.textHintLight),
            const SizedBox(height: 16),
            Text(
              'No join requests yet',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Requests from travellers who want to join your trip will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textHintLight,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
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

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
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
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 15, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
