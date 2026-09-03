import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model — replace with real API model later
// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight data class for a single trip card.
///
/// When the backend integration phase begins, map the API response
/// directly to this class (or replace it with the actual model).
class TripCardData {
  const TripCardData({
    required this.id,
    required this.title,
    required this.location,
    required this.dateRange,
    required this.companionCount,
    required this.budget,
    required this.illustrationSeed,
    required this.tag,
  });

  /// Unique identifier (used as Hero tag etc. when navigating).
  final String id;

  /// Trip / destination name — e.g. "Nahargarh Fort, Jaipur".
  final String title;

  /// City / region — e.g. "Jaipur, Rajasthan".
  final String location;

  /// Human-readable date range — e.g. "20 Aug – 25 Aug".
  final String dateRange;

  /// How many companions are already in / are looking for.
  final int companionCount;

  /// Budget hint — e.g. "₹900 – ₹1500".
  final String budget;

  /// Seed used to deterministically pick illustration palette & shapes.
  final int illustrationSeed;

  /// Short category label — e.g. "Fort", "Beach", "Hill Station".
  final String tag;
}

// ─────────────────────────────────────────────────────────────────────────────
// TripCard widget
// ─────────────────────────────────────────────────────────────────────────────

/// A polished trip card widget designed for the Tripromio Home screen.
///
/// The illustration area is drawn with [CustomPaint] — no image assets
/// are required. Swap [_TripIllustration] for [Image.asset] / [Image.network]
/// when real assets become available.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.data, this.onTap});

  final TripCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Illustration area ─────────────────────────────────────
              SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _TripIllustration(seed: data.illustrationSeed),
                    // Gradient overlay for text legibility
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tag chip — top-left
                    Positioned(
                      top: AppConstants.spacingSm,
                      left: AppConstants.spacingSm,
                      child: _TagChip(label: data.tag, seed: data.illustrationSeed),
                    ),
                    // Companion count — top-right
                    Positioned(
                      top: AppConstants.spacingSm,
                      right: AppConstants.spacingSm,
                      child: _CompanionBadge(count: data.companionCount),
                    ),
                    // Location name over gradient
                    Positioned(
                      bottom: AppConstants.spacingSm,
                      left: AppConstants.spacingMd,
                      right: AppConstants.spacingMd,
                      child: Text(
                        data.title,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              color: Colors.black38,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card body ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location row
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.location,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXs),

                    // Meta row — dates + budget
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.dateRange,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.currency_rupee_rounded,
                          size: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                        Text(
                          data.budget,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Action row
                    Row(
                      children: [
                        // Companion avatars
                        _AvatarStack(seed: data.illustrationSeed),
                        const SizedBox(width: AppConstants.spacingSm),
                        Text(
                          '${data.companionCount} looking',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const Spacer(),
                        _ConnectButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.seed});

  final String label;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

class _CompanionBadge extends StatelessWidget {
  const _CompanionBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.seed});

  final int seed;

  static const List<Color> _avatarColors = [
    Color(0xFF5B6CF8),
    Color(0xFF3DAF8A),
    Color(0xFFFF7B54),
    Color(0xFFFFB347),
  ];

  @override
  Widget build(BuildContext context) {
    const count = 3;
    const size = 24.0;
    const overlap = 14.0;

    return SizedBox(
      width: size + overlap * (count - 1),
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          final color = _avatarColors[(seed + i) % _avatarColors.length];
          return Positioned(
            left: i * overlap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 13,
                  color: color,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        'Connect',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trip illustration (pure CustomPaint — no assets required)
// Swap for Image.asset() / Image.network() in a future phase.
// ─────────────────────────────────────────────────────────────────────────────

class _TripIllustration extends StatelessWidget {
  const _TripIllustration({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TripScenePainter(seed: seed),
    );
  }
}

class _TripScenePainter extends CustomPainter {
  _TripScenePainter({required this.seed});

  final int seed;

  // Deterministic palette from seed
  static const List<List<Color>> _palettes = [
    [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)], // deep indigo
    [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)], // deep teal
    [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)], // deep green
    [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)], // deep purple
    [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)], // deep blue
    [Color(0xFF880E4F), Color(0xFFC2185B), Color(0xFFD81B60)], // deep pink
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final palette = _palettes[seed % _palettes.length];
    final skyTop = palette[0];
    final skyBot = palette[1];
    final ground = palette[2];

    // Sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyBot],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Stars / dots
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (int i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * 0.5),
        rng.nextDouble() * 1.5 + 0.5,
        starPaint,
      );
    }

    // Mountains / hills
    _drawHills(canvas, size, ground, rng);

    // Silhouette landmark
    _drawLandmark(canvas, size, Colors.black.withValues(alpha: 0.55), rng);

    // Ground strip
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      Paint()..color = ground.withValues(alpha: 0.60),
    );

    // Subtle texture overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );
  }

  void _drawHills(Canvas canvas, Size size, Color color, math.Random rng) {
    final paint = Paint()..color = color.withValues(alpha: 0.45);
    final paint2 = Paint()..color = color.withValues(alpha: 0.30);

    // Far hill
    final far = Path();
    far.moveTo(0, size.height * 0.70);
    far.quadraticBezierTo(
        size.width * 0.25, size.height * 0.30, size.width * 0.55, size.height * 0.60);
    far.quadraticBezierTo(
        size.width * 0.75, size.height * 0.78, size.width, size.height * 0.65);
    far.lineTo(size.width, size.height);
    far.lineTo(0, size.height);
    far.close();
    canvas.drawPath(far, paint2);

    // Near hill
    final near = Path();
    near.moveTo(0, size.height * 0.82);
    near.quadraticBezierTo(
        size.width * 0.30, size.height * 0.55, size.width * 0.60, size.height * 0.72);
    near.quadraticBezierTo(
        size.width * 0.80, size.height * 0.82, size.width, size.height * 0.75);
    near.lineTo(size.width, size.height);
    near.lineTo(0, size.height);
    near.close();
    canvas.drawPath(near, paint);
  }

  void _drawLandmark(Canvas canvas, Size size, Color color, math.Random rng) {
    // Different landmark shapes based on seed
    final style = seed % 4;
    final cx = size.width * 0.62;
    final base = size.height * 0.60;
    final p = Paint()..color = color;

    switch (style) {
      case 0: // Fort / castle silhouette
        _drawFort(canvas, cx, base, size, p);
      case 1: // Mountain peak
        _drawPeak(canvas, cx, base, size, p);
      case 2: // Dome / monument
        _drawDome(canvas, cx, base, size, p);
      default: // Tree line
        _drawTrees(canvas, cx, base, size, p, rng);
    }
  }

  void _drawFort(Canvas canvas, double cx, double base, Size size, Paint p) {
    // Base wall
    canvas.drawRect(Rect.fromLTWH(cx - 45, base - 40, 90, 40), p);
    // Battlements
    for (int i = 0; i < 6; i++) {
      canvas.drawRect(Rect.fromLTWH(cx - 45 + i * 17, base - 52, 10, 14), p);
    }
    // Tower left
    canvas.drawRect(Rect.fromLTWH(cx - 55, base - 68, 22, 68), p);
    canvas.drawRect(Rect.fromLTWH(cx - 60, base - 78, 10, 12), p);
    canvas.drawRect(Rect.fromLTWH(cx - 48, base - 78, 10, 12), p);
    // Tower right
    canvas.drawRect(Rect.fromLTWH(cx + 33, base - 68, 22, 68), p);
    canvas.drawRect(Rect.fromLTWH(cx + 33, base - 78, 10, 12), p);
    canvas.drawRect(Rect.fromLTWH(cx + 45, base - 78, 10, 12), p);
    // Gate arch
    final arch = Path()
      ..addArc(Rect.fromCenter(center: Offset(cx, base - 2), width: 22, height: 28),
          math.pi, math.pi);
    canvas.drawPath(arch, p);
    canvas.drawRect(Rect.fromLTWH(cx - 11, base - 16, 22, 16), p);
  }

  void _drawPeak(Canvas canvas, double cx, double base, Size size, Paint p) {
    final peak = Path()
      ..moveTo(cx - 55, base)
      ..lineTo(cx, base - 70)
      ..lineTo(cx + 55, base)
      ..close();
    canvas.drawPath(peak, p);
    final snow = Path()
      ..moveTo(cx - 16, base - 50)
      ..lineTo(cx, base - 70)
      ..lineTo(cx + 16, base - 50)
      ..close();
    canvas.drawPath(snow, Paint()..color = Colors.white.withValues(alpha: 0.55));
  }

  void _drawDome(Canvas canvas, double cx, double base, Size size, Paint p) {
    // Plinth
    canvas.drawRect(Rect.fromLTWH(cx - 40, base - 20, 80, 20), p);
    // Pillars
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(cx - 35 + i * 24, base - 52, 8, 32), p);
    }
    // Dome
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, base - 64), width: 48, height: 36), p);
    // Spire
    canvas.drawRect(Rect.fromLTWH(cx - 2, base - 90, 4, 24), p);
    canvas.drawCircle(Offset(cx, base - 94), 4, p);
  }

  void _drawTrees(Canvas canvas, double cx, double base, Size size, Paint p,
      math.Random rng) {
    for (int i = 0; i < 7; i++) {
      final tx = cx - 60 + i * 20.0;
      final th = 28.0 + rng.nextDouble() * 18;
      final tree = Path()
        ..moveTo(tx - 10, base)
        ..lineTo(tx, base - th)
        ..lineTo(tx + 10, base)
        ..close();
      canvas.drawPath(tree, p);
      canvas.drawRect(Rect.fromLTWH(tx - 2, base - 8, 4, 10), p);
    }
  }

  @override
  bool shouldRepaint(covariant _TripScenePainter old) => old.seed != seed;
}
