import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/profile_service.dart';
import '../../../routes/app_routes.dart';

/// Displays the authenticated user's full profile.
///
/// Data is loaded fresh from GET /api/profile on every open so that
/// edits made in [EditProfileScreen] are reflected immediately.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();

  UserModel? _user;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final user = await _service.getProfile();
      if (!mounted) return;
      setState(() => _user = user);
    } on NetworkException {
      if (!mounted) return;
      setState(() => _errorMessage = 'No internet connection. Please retry.');
    } on UnauthorizedException {
      if (!mounted) return;
      setState(
          () => _errorMessage = 'Session expired. Please log in again.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).pushNamed(
      AppRoutes.editProfile,
      arguments: _user,
    );
    if (updated is UserModel && mounted) {
      setState(() => _user = updated);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _loading
          ? const _LoadingBody()
          : _errorMessage != null
              ? _ErrorBody(message: _errorMessage!, onRetry: _load)
              : _ProfileBody(user: _user!, onEdit: _openEdit),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading state
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(32, topPad + 16, 32, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main profile body
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user, required this.onEdit});

  final UserModel user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header / hero
        SliverToBoxAdapter(child: _ProfileHeader(user: user, onEdit: onEdit)),

        // Profile completion bar
        if (user.profileCompletion < 100)
          SliverToBoxAdapter(
            child: _CompletionBar(percent: user.profileCompletion),
          ),

        // Sections
        SliverToBoxAdapter(child: _AboutSection(user: user)),
        SliverToBoxAdapter(child: _TravelSection(user: user)),
        SliverToBoxAdapter(child: _BudgetSection(user: user)),

        // Bottom breathing room
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header hero
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEdit});

  final UserModel user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Top row: back + edit
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
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              Text(
                'My Profile',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            user.name,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),

          // Location
          if (_location(user) != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.65)),
                const SizedBox(width: 4),
                Text(
                  _location(user)!,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _location(UserModel u) {
    final parts = [u.profile?.city, u.profile?.country]
        .whereType<String>()
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile completion bar
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Profile completion',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your profile to find better travel companions.',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textHintLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About section
// ─────────────────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final bio = user.profile?.bio;
    final langs = user.profile?.languages ?? [];

    return _Section(
      title: 'About',
      icon: Icons.person_outline_rounded,
      children: [
        if (bio != null && bio.isNotEmpty)
          Text(
            bio,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
              height: 1.6,
            ),
          )
        else
          _EmptyHint(text: 'Add a bio to help companions get to know you.'),
        if (langs.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: langs
                .map((l) => _Tag(label: l, icon: Icons.language_rounded))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Travel section
// ─────────────────────────────────────────────────────────────────────────────

class _TravelSection extends StatelessWidget {
  const _TravelSection({required this.user});

  final UserModel user;

  static const Map<String, String> _styleLabels = {
    'adventure': '🏔️ Adventure',
    'backpacking': '🎒 Backpacking',
    'budget': '💰 Budget',
    'luxury': '✨ Luxury',
    'relaxed': '🌴 Relaxed',
    'road_trip': '🚗 Road Trip',
    'nature': '🌿 Nature',
    'cultural': '🏛️ Cultural',
  };

  @override
  Widget build(BuildContext context) {
    final style = user.profile?.travelStyle;
    final interests = user.interests;

    return _Section(
      title: 'Travel Style',
      icon: Icons.explore_rounded,
      children: [
        if (style != null)
          _Tag(
            label: _styleLabels[style] ?? style,
            icon: Icons.backpack_rounded,
          )
        else
          _EmptyHint(text: 'Add your travel style.'),
        if (interests.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                interests.map((i) => _Tag(label: i)).toList(),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget section
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetSection extends StatelessWidget {
  const _BudgetSection({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final min = user.profile?.preferredBudgetMin;
    final max = user.profile?.preferredBudgetMax;

    String budgetText = '';
    if (min != null && max != null) {
      budgetText =
          '₹${_fmt(min)} – ₹${_fmt(max)}';
    } else if (min != null) {
      budgetText = 'From ₹${_fmt(min)}';
    } else if (max != null) {
      budgetText = 'Up to ₹${_fmt(max)}';
    }

    return _Section(
      title: 'Preferred Budget',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        if (budgetText.isNotEmpty)
          _Tag(label: budgetText, icon: Icons.currency_rupee_rounded)
        else
          _EmptyHint(text: 'Add your preferred budget range.'),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared section container
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag chip
// ─────────────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty hint
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 13,
        color: AppColors.textHintLight,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
