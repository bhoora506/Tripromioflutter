import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_member_model.dart';
import '../../../data/services/trip_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TripMembersScreen
// ─────────────────────────────────────────────────────────────────────────────

class TripMembersScreen extends StatefulWidget {
  const TripMembersScreen({super.key});

  @override
  State<TripMembersScreen> createState() => _TripMembersScreenState();
}

class _TripMembersScreenState extends State<TripMembersScreen> {
  final _tripService = TripService();

  int? _tripId;
  List<TripMemberModel> _members = [];
  bool _loading = true;
  String? _errorMessage;
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
      final members = await _tripService.getTripMembers(_tripId!);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } on ForbiddenException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'You are not allowed to view these members.';
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
          'Trip Members',
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

    if (_members.isEmpty) {
      return _EmptyView(onRefresh: _load);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          AppConstants.screenPaddingH,
          AppConstants.spacingMd,
          AppConstants.screenPaddingH,
          MediaQuery.paddingOf(context).bottom + AppConstants.spacingLg,
        ),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return _MemberCard(member: member);
        },
      ),
    );
  }
}

// ── Member card ──────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final TripMemberModel member;

  @override
  Widget build(BuildContext context) {
    final bool isOwner = member.role.toLowerCase() == 'owner';

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Avatar
          _Initials(name: member.userName, seed: member.userId),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                if (member.joinedAt != null && !isOwner) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Joined ${_formatDate(member.joinedAt!)}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _RoleBadge(role: member.role),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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

// ── Role badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final isOwner = role.toLowerCase() == 'owner';

    final bg = isOwner
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.success.withValues(alpha: 0.12);
    final fg = isOwner ? AppColors.primary : AppColors.success;
    final label = isOwner ? 'Owner' : 'Member';

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
            const Icon(Icons.group_off_rounded,
                size: 56, color: AppColors.textHintLight),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight,
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
