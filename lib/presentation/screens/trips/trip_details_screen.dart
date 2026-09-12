import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/trip_service.dart';
import '../../../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TripDetailsScreen — real API
// ─────────────────────────────────────────────────────────────────────────────

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _tripService = TripService();
  final _profileService = ProfileService();

  TripModel? _trip;
  int? _currentUserId;
  bool _loading = true;
  String? _errorMessage;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _trip == null && _errorMessage == null) {
      _loadTrip();
    }
  }

  @override
  void dispose() {
    _tripService.dispose();
    _profileService.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _profileService.getProfile();
      if (mounted) setState(() => _currentUserId = user.id);
    } catch (_) {
      // Non-critical — ownership checks will just fail safe (no actions shown)
    }
  }

  Future<void> _loadTrip() async {
    final args = ModalRoute.of(context)?.settings.arguments;

    int? tripId;
    if (args is int) {
      tripId = args;
    } else if (args is TripModel) {
      // If a full model was passed, use it immediately and refresh in background
      setState(() {
        _trip = args;
        _loading = false;
      });
      tripId = args.id;
      // Refresh in background to get latest data
      _refreshTrip(tripId);
      return;
    }

    if (tripId == null) {
      setState(() {
        _errorMessage = 'No trip ID provided.';
        _loading = false;
      });
      return;
    }

    try {
      final trip = await _tripService.getTrip(tripId);
      if (!mounted) return;
      setState(() {
        _trip = trip;
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

  Future<void> _refreshTrip(int tripId) async {
    try {
      final trip = await _tripService.getTrip(tripId);
      if (mounted) setState(() => _trip = trip);
    } catch (_) {
      // Silently fail on background refresh
    }
  }

  bool get _isOwner {
    if (_currentUserId == null || _trip?.owner == null) return false;
    return _trip!.owner!.id == _currentUserId;
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _publishTrip() async {
    if (_actionInProgress || _trip == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Trip?'),
        content: const Text(
            'This trip will become visible to other travellers. You can cancel it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not yet'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    try {
      final updated = await _tripService.publishTrip(_trip!.id);
      if (!mounted) return;
      setState(() => _trip = updated);
      _showSnack('Trip published!', isSuccess: true);
    } on ConflictException catch (e) {
      if (mounted) _showSnack(e.message);
    } on ValidationException catch (e) {
      if (mounted) _showSnack(e.message);
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _cancelTrip() async {
    if (_actionInProgress || _trip == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Trip?'),
        content: const Text(
            'This action cannot be undone. The trip will be permanently cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cancel Trip',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    try {
      final updated = await _tripService.cancelTrip(_trip!.id);
      if (!mounted) return;
      setState(() => _trip = updated);
      _showSnack('Trip cancelled.', isSuccess: true);
    } on ConflictException catch (e) {
      if (mounted) _showSnack(e.message);
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _editTrip() async {
    if (_trip == null) return;
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.editTrip,
      arguments: _trip,
    );
    if (result is TripModel && mounted) {
      setState(() => _trip = result);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(AppConstants.screenPaddingH),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 56, color: AppColors.textSecondaryLight),
                const SizedBox(height: 16),
                Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 15, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _errorMessage = null;
                    });
                    _loadTrip();
                  },
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
        ),
      );
    }

    final trip = _trip!;
    final botPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _TripHero(
                destination: trip.destination,
                seed: trip.id,
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPaddingH,
                  AppConstants.spacingLg,
                  AppConstants.screenPaddingH,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            trip.title,
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        _StatusChip(status: trip.status),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingXs),

                    // Location
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.destination,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Info chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        if (trip.startDate != null && trip.endDate != null)
                          _DetailChip(
                            icon: Icons.calendar_today_rounded,
                            label:
                                '${_formatDate(trip.startDate!)} – ${_formatDate(trip.endDate!)}',
                          ),
                        if (trip.startDate != null) const SizedBox(width: AppConstants.spacingSm),
                        _DetailChip(
                          icon: Icons.people_rounded,
                          label:
                              '${trip.memberCount}/${trip.maxMembers} members',
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        if (trip.budgetMin != null || trip.budgetMax != null)
                          _DetailChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: _formatBudget(trip),
                          ),
                        if (trip.budgetMin != null || trip.budgetMax != null)
                          const SizedBox(width: AppConstants.spacingSm),
                        if (trip.tripType != null)
                          _DetailChip(
                            icon: Icons.hiking_rounded,
                            label: _tripTypeLabel(trip.tripType!),
                          ),
                      ]),
                    ),

                    if (trip.remainingSlots > 0) ...[
                      const SizedBox(height: AppConstants.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusFull),
                        ),
                        child: Text(
                          '${trip.remainingSlots} slot${trip.remainingSlots == 1 ? '' : 's'} remaining',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppConstants.spacingLg),

                    // Description
                    if (trip.description != null &&
                        trip.description!.isNotEmpty) ...[
                      Text('About This Trip',
                          style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight)),
                      const SizedBox(height: AppConstants.spacingSm),
                      Text(
                        trip.description!,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppColors.textSecondaryLight,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingLg),
                    ],

                    // Interests
                    if (trip.interests.isNotEmpty) ...[
                      Text('Trip Interests',
                          style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight)),
                      const SizedBox(height: AppConstants.spacingSm),
                      Wrap(
                        spacing: AppConstants.spacingSm,
                        runSpacing: AppConstants.spacingSm,
                        children: trip.interests
                            .map((i) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radiusFull),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    i.name,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: AppConstants.spacingLg),
                    ],

                    // Trip Host
                    if (trip.owner != null) ...[
                      Text('Trip Host',
                          style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight)),
                      const SizedBox(height: AppConstants.spacingMd),
                      _OwnerCard(owner: trip.owner!, isCurrentUser: _isOwner),
                      const SizedBox(height: AppConstants.spacingLg),
                    ],

                    // Bottom space for the sticky buttons
                    SizedBox(height: botPad + 120),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Sticky bottom actions ─────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickyActions(
            trip: trip,
            isOwner: _isOwner,
            actionInProgress: _actionInProgress,
            botPad: botPad,
            onEdit: _editTrip,
            onPublish: _publishTrip,
            onCancel: _cancelTrip,
          ),
        ),
      ]),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _formatDate(String dateStr) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  try {
    final parts = dateStr.split('-');
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return '$day ${months[month]}';
  } catch (_) {
    return dateStr;
  }
}

String _formatBudget(TripModel trip) {
  String fmtNum(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : n.toStringAsFixed(0);

  if (trip.budgetMin != null && trip.budgetMax != null) {
    return '₹${fmtNum(trip.budgetMin!)} – ₹${fmtNum(trip.budgetMax!)}';
  }
  if (trip.budgetMin != null) return 'From ₹${fmtNum(trip.budgetMin!)}';
  if (trip.budgetMax != null) return 'Up to ₹${fmtNum(trip.budgetMax!)}';
  return '';
}

String _tripTypeLabel(TripType type) {
  switch (type) {
    case TripType.weekend:      return 'Weekend';
    case TripType.adventure:    return 'Adventure';
    case TripType.backpacking:  return 'Backpacking';
    case TripType.roadTrip:     return 'Road Trip';
    case TripType.nature:       return 'Nature';
    case TripType.photography:  return 'Photography';
    case TripType.cultural:     return 'Cultural';
    case TripType.beach:        return 'Beach';
    case TripType.mountains:    return 'Mountains';
    case TripType.other:        return 'Other';
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _TripHero extends StatelessWidget {
  const _TripHero({required this.destination, required this.seed});
  final String destination;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Stack(children: [
      SizedBox(
        height: 280,
        width: double.infinity,
        child: CustomPaint(painter: _HeroPainter(seed: seed)),
      ),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
      ),
      Positioned(
        top: topPad + AppConstants.spacingMd,
        left: AppConstants.screenPaddingH,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 17),
          ),
        ),
      ),
      Positioned(
        left: AppConstants.screenPaddingH,
        right: AppConstants.screenPaddingH,
        bottom: AppConstants.spacingMd,
        child: Text(
          destination,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              Shadow(
                  blurRadius: 8,
                  color: Colors.black.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _HeroPainter extends CustomPainter {
  const _HeroPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed * 997 + 13);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromARGB(255, 20 + rng.nextInt(40), 80 + rng.nextInt(80),
              180 + rng.nextInt(60)),
          Color.fromARGB(
              255, 140 + rng.nextInt(60), 180 + rng.nextInt(50), 230),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    _drawMountain(canvas, size, rng,
        colors: [const Color(0xFF4A7C99), const Color(0xFF5B9BB5)],
        heightFactor: 0.55);
    _drawMountain(canvas, size, rng,
        colors: [const Color(0xFF2D6B7A), const Color(0xFF3D8A9E)],
        heightFactor: 0.65);
    _drawMountain(canvas, size, rng,
        colors: [const Color(0xFF1A4F5F), const Color(0xFF245E70)],
        heightFactor: 0.78);

    final groundPaint = Paint()..color = const Color(0xFF1A3D2B);
    final groundPath = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width, size.height * 0.82)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(groundPath, groundPaint);
  }

  void _drawMountain(Canvas canvas, Size size, math.Random rng,
      {required List<Color> colors, required double heightFactor}) {
    final paint = Paint()
      ..shader = LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    path.moveTo(0, size.height);
    double x = 0;
    while (x < size.width) {
      final peakX = x + 30 + rng.nextDouble() * 80;
      final peakY = size.height * (heightFactor - rng.nextDouble() * 0.15);
      path.lineTo(peakX, peakY);
      x = peakX + 20 + rng.nextDouble() * 60;
      path.lineTo(
          x, size.height * (heightFactor + 0.05 + rng.nextDouble() * 0.10));
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) => old.seed != seed;
}

// ── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case TripStatus.draft:
        bgColor = AppColors.warning.withValues(alpha: 0.12);
        textColor = AppColors.warning;
        label = 'Draft';
      case TripStatus.published:
        bgColor = AppColors.success.withValues(alpha: 0.12);
        textColor = AppColors.success;
        label = 'Published';
      case TripStatus.ongoing:
        bgColor = AppColors.info.withValues(alpha: 0.12);
        textColor = AppColors.info;
        label = 'Ongoing';
      case TripStatus.completed:
        bgColor = AppColors.textSecondaryLight.withValues(alpha: 0.12);
        textColor = AppColors.textSecondaryLight;
        label = 'Completed';
      case TripStatus.cancelled:
        bgColor = AppColors.error.withValues(alpha: 0.12);
        textColor = AppColors.error;
        label = 'Cancelled';
      default:
        bgColor = AppColors.textSecondaryLight.withValues(alpha: 0.12);
        textColor = AppColors.textSecondaryLight;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Detail chips ──────────────────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ]),
    );
  }
}

// ── Owner card ───────────────────────────────────────────────────────────────

const _kAvatarColorsDetails = [
  [Color(0xFF5B6CF8), Color(0xFF9B7CF8)],
  [Color(0xFFF85B6C), Color(0xFFF87C5B)],
  [Color(0xFF5BF8A0), Color(0xFF5BDDF8)],
  [Color(0xFFF8D45B), Color(0xFFF89F5B)],
  [Color(0xFF5BB8F8), Color(0xFF5B6CF8)],
];

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner, required this.isCurrentUser});
  final TripOwnerModel owner;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final idx = owner.id % _kAvatarColorsDetails.length;
    final colors = _kAvatarColorsDetails[idx];
    final initials =
        owner.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: Center(
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(owner.name,
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight)),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusFull),
                        ),
                        child: Text('You',
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Trip organizer',
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight)),
              ]),
        ),
      ]),
    );
  }
}

// ── Sticky actions ───────────────────────────────────────────────────────────

class _StickyActions extends StatelessWidget {
  const _StickyActions({
    required this.trip,
    required this.isOwner,
    required this.actionInProgress,
    required this.botPad,
    required this.onEdit,
    required this.onPublish,
    required this.onCancel,
  });

  final TripModel trip;
  final bool isOwner;
  final bool actionInProgress;
  final double botPad;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    // Determine which actions to show based on ownership + status
    final bool canEdit = isOwner &&
        (trip.status == TripStatus.draft ||
            trip.status == TripStatus.published ||
            trip.status == TripStatus.ongoing);
    final bool canPublish =
        isOwner && trip.status == TripStatus.draft;
    final bool canCancel = isOwner &&
        (trip.status == TripStatus.draft ||
            trip.status == TripStatus.published ||
            trip.status == TripStatus.ongoing);

    // If no actions available (not owner, or terminal status), show nothing
    if (!canEdit && !canPublish && !canCancel) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.screenPaddingH,
        AppConstants.spacingMd,
        AppConstants.screenPaddingH,
        botPad + AppConstants.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(children: [
        // Cancel (destructive, outlined)
        if (canCancel)
          Expanded(
            child: OutlinedButton(
              onPressed: actionInProgress ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.5)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd)),
                textStyle: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: const Text('Cancel Trip'),
            ),
          ),
        if (canCancel && (canEdit || canPublish))
          const SizedBox(width: AppConstants.spacingSm),

        // Edit
        if (canEdit)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: actionInProgress ? null : onEdit,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd)),
                textStyle: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (canEdit && canPublish)
          const SizedBox(width: AppConstants.spacingSm),

        // Publish (primary, filled)
        if (canPublish)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: actionInProgress ? null : onPublish,
              icon: actionInProgress
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.publish_rounded, size: 16),
              label: const Text('Publish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd)),
                textStyle: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ]),
    );
  }
}
