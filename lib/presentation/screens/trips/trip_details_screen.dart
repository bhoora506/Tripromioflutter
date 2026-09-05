import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../companions/search_results_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TripDetailsScreen
// ─────────────────────────────────────────────────────────────────────────────

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final args = ModalRoute.of(context)?.settings.arguments;
    final traveller = args is TravellerData ? args : null;

    final name = traveller?.name ?? 'Manali Trek Adventure';
    final destination = traveller?.destination ?? 'Manali, Himachal Pradesh';
    final dateRange = traveller?.dateRange ?? '15 Sep – 22 Sep';
    final bio = traveller?.bio ??
        'An incredible 7-day trek through the stunning landscapes of Manali. '
            'We\'ll explore Rohtang Pass, Solang Valley, and spend a night at a high-altitude camp. '
            'The trip includes guided trekking, local cuisine experiences, and bonfire nights under the stars.';
    final rating = traveller?.rating ?? 4.8;
    final tripsCount = traveller?.tripsCount ?? 14;

    final botPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero image area ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _TripHero(
                destination: destination,
                seed: traveller?.avatarSeed ?? 0,
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
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
                    // Title + rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        _RatingBadge(rating: rating),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingXs),

                    // Location
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(destination,
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight)),
                    ]),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Info chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _DetailChip(
                            icon: Icons.calendar_today_rounded,
                            label: dateRange),
                        const SizedBox(width: AppConstants.spacingSm),
                        _DetailChip(
                            icon: Icons.people_rounded,
                            label: '${traveller?.tripsCount ?? 4} companions'),
                        const SizedBox(width: AppConstants.spacingSm),
                        _DetailChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Rs.1,000 – Rs.3,000'),
                        const SizedBox(width: AppConstants.spacingSm),
                        _DetailChip(
                            icon: Icons.hiking_rounded, label: 'Adventure'),
                      ]),
                    ),

                    const SizedBox(height: AppConstants.spacingLg),

                    // About section
                    Text('About This Trip',
                        style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight)),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(bio,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                            height: 1.6)),

                    const SizedBox(height: AppConstants.spacingLg),

                    // Host info
                    Text('Trip Host',
                        style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight)),
                    const SizedBox(height: AppConstants.spacingMd),
                    _HostCard(
                      name: traveller?.name ?? 'Priya Sharma',
                      tripsCount: tripsCount,
                      rating: rating,
                      avatarSeed: traveller?.avatarSeed ?? 0,
                    ),

                    const SizedBox(height: AppConstants.spacingLg),

                    // Members
                    Text('Current Members',
                        style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight)),
                    const SizedBox(height: AppConstants.spacingMd),
                    _MembersRow(),

                    // Bottom space for the sticky buttons
                    SizedBox(height: botPad + 120),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Sticky bottom buttons ────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickyButtons(botPad: botPad),
        ),
      ]),
    );
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
      // Painted hero image
      SizedBox(
        height: 280,
        width: double.infinity,
        child: CustomPaint(painter: _HeroPainter(seed: seed)),
      ),

      // Gradient overlay (bottom fade)
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

      // Back button
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

      // Destination label at bottom of hero
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
              shadows: [Shadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.6))]),
        ),
      ),
    ]);
  }
}

/// A deterministic landscape painter for the hero area.
class _HeroPainter extends CustomPainter {
  const _HeroPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed * 997 + 13);

    // Sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromARGB(255, 20 + rng.nextInt(40), 80 + rng.nextInt(80), 180 + rng.nextInt(60)),
          Color.fromARGB(255, 140 + rng.nextInt(60), 180 + rng.nextInt(50), 230),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Far mountains
    _drawMountain(canvas, size, rng,
        colors: [const Color(0xFF4A7C99), const Color(0xFF5B9BB5)],
        heightFactor: 0.55);

    // Mid mountains
    _drawMountain(canvas, size, rng,
        colors: [const Color(0xFF2D6B7A), const Color(0xFF3D8A9E)],
        heightFactor: 0.65);

    // Foreground mountains (darker)
    _drawMountain(canvas, size, rng,
        colors: [const Color(0xFF1A4F5F), const Color(0xFF245E70)],
        heightFactor: 0.78);

    // Ground
    final groundPaint = Paint()
      ..color = const Color(0xFF1A3D2B);
    final groundPath = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width, size.height * 0.82)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(groundPath, groundPaint);
  }

  void _drawMountain(
    Canvas canvas,
    Size size,
    math.Random rng, {
    required List<Color> colors,
    required double heightFactor,
  }) {
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
      path.lineTo(x, size.height * (heightFactor + 0.05 + rng.nextDouble() * 0.10));
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) => old.seed != seed;
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

// ── Rating badge ──────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
        const SizedBox(width: 3),
        Text('$rating',
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7A5C00))),
      ]),
    );
  }
}

// ── Host card ─────────────────────────────────────────────────────────────────

const _kAvatarColorsDetails = [
  [Color(0xFF5B6CF8), Color(0xFF9B7CF8)],
  [Color(0xFFF85B6C), Color(0xFFF87C5B)],
  [Color(0xFF5BF8A0), Color(0xFF5BDDF8)],
  [Color(0xFFF8D45B), Color(0xFFF89F5B)],
  [Color(0xFF5BB8F8), Color(0xFF5B6CF8)],
];

class _HostCard extends StatelessWidget {
  const _HostCard({
    required this.name,
    required this.tripsCount,
    required this.rating,
    required this.avatarSeed,
  });

  final String name;
  final int tripsCount;
  final double rating;
  final int avatarSeed;

  @override
  Widget build(BuildContext context) {
    final idx = avatarSeed % _kAvatarColorsDetails.length;
    final colors = _kAvatarColorsDetails[idx];
    final initials =
        name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(children: [
        // Avatar
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

        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.backpack_rounded,
                  size: 12, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Text('$tripsCount trips completed',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight)),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded,
                  size: 12, color: Color(0xFFFFB800)),
              const SizedBox(width: 3),
              Text('$rating',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight)),
            ]),
          ]),
        ),

        // Verified badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(Icons.verified_rounded,
                size: 12, color: AppColors.success),
            const SizedBox(width: 3),
            Text('Verified',
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success)),
          ]),
        ),
      ]),
    );
  }
}

// ── Members row ───────────────────────────────────────────────────────────────

class _MembersRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const members = [
      ('Raj', 0), ('Sita', 2), ('Mohan', 3),
    ];

    return Row(children: [
      ...members.map(((String name, int seed) rec) {
        final idx = rec.$2 % _kAvatarColorsDetails.length;
        final colors = _kAvatarColorsDetails[idx];
        return Padding(
          padding: const EdgeInsets.only(right: AppConstants.spacingSm),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(rec.$1[0],
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 4),
            Text(rec.$1,
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight)),
          ]),
        );
      }),
      // +More slot
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundLight,
          border: Border.all(color: AppColors.borderLight, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.add_rounded,
              size: 18, color: AppColors.textSecondaryLight),
        ),
      ),
    ]);
  }
}

// ── Sticky buttons ────────────────────────────────────────────────────────────

class _StickyButtons extends StatelessWidget {
  const _StickyButtons({required this.botPad});
  final double botPad;

  @override
  Widget build(BuildContext context) {
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
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(children: [
        // Chat with host (outlined)
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat coming soon!',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(AppConstants.screenPaddingH),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text("Chat"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
              textStyle:
                  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),

        // I'm Interested (filled)
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Interest registered! Host will be notified.',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(AppConstants.screenPaddingH),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.favorite_border_rounded, size: 16),
            label: const Text("I'm Interested"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
              textStyle:
                  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }
}
