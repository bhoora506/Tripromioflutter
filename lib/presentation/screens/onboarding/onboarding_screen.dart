import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.painter,
    required this.accentColor,
    required this.secondaryColor,
  });

  final String title;
  final String subtitle;
  final CustomPainter painter;
  final Color accentColor;
  final Color secondaryColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen onboarding flow shown after the splash screen.
///
/// Lifecycle:
///   Splash → navigates here → 3 swipeable pages → "Get Started" → Home.
///
/// Navigation guards:
///   "Skip" and "Get Started" both push [AppRoutes.home].
///   Until Home is built, the existing [PlaceholderScreen] for Home shows.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _tokenStorage = TokenStorage();

  late AnimationController _textAnimController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  static final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Find Your Travel\nCompanion',
      subtitle:
          'Connect with travelers who share your destination, plans and travel interests.',
      painter: const _CompassPainter(),
      accentColor: const Color(0xFF5B6CF8),
      secondaryColor: const Color(0xFF8B9CF8),
    ),
    _OnboardingData(
      title: 'Plan Trips\nTogether',
      subtitle:
          'Create your trip, discover companions and organise your journey from start to finish.',
      painter: const _MapPainter(),
      accentColor: const Color(0xFF3DAF8A),
      secondaryColor: const Color(0xFF70CDB3),
    ),
    _OnboardingData(
      title: 'Travel Better.\nTravel Safer.',
      subtitle:
          'Build trusted travel connections with verified profiles, ratings and safety-focused features.',
      painter: const _ShieldPainter(),
      accentColor: const Color(0xFFFF7B54),
      secondaryColor: const Color(0xFFFFAA85),
    ),
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _textAnimController = AnimationController(
      vsync: this,
      duration: AppConstants.animationNormal,
    );

    _textFade = CurvedAnimation(
      parent: _textAnimController,
      curve: Curves.easeOut,
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textAnimController,
      curve: Curves.easeOut,
    ));

    _textAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textAnimController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _isLastPage => _currentPage == _pages.length - 1;

  _OnboardingData get _current => _pages[_currentPage];

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _textAnimController
      ..reset()
      ..forward();
  }

  void _goNext() {
    if (!_isLastPage) {
      _pageController.nextPage(
        duration: AppConstants.animationNormal,
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  /// Called when the user finishes or skips onboarding.
  ///
  /// Marks onboarding as done so it is never shown again, then sends the
  /// unauthenticated user to the Login screen.
  Future<void> _finish() async {
    await _tokenStorage.setOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(isLastPage: _isLastPage, onSkip: _finish),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemCount: _pages.length,
                itemBuilder: (_, index) => _PageSlide(
                  data: _pages[index],
                  textFade: index == _currentPage ? _textFade : null,
                  textSlide: index == _currentPage ? _textSlide : null,
                ),
              ),
            ),
            _BottomControls(
              pageCount: _pages.length,
              currentPage: _currentPage,
              isLastPage: _isLastPage,
              accentColor: _current.accentColor,
              onNext: _goNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar  (logo + skip)
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isLastPage, required this.onSkip});

  final bool isLastPage;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenPaddingH,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/tripromio_logo.jpg',
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          if (!isLastPage)
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusFull),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Text(
                'Skip',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual page slide
// ─────────────────────────────────────────────────────────────────────────────

class _PageSlide extends StatelessWidget {
  const _PageSlide({
    required this.data,
    required this.textFade,
    required this.textSlide,
  });

  final _OnboardingData data;
  final Animation<double>? textFade;
  final Animation<Offset>? textSlide;

  @override
  Widget build(BuildContext context) {
    Widget textContent = _TextBlock(data: data);

    if (textFade != null && textSlide != null) {
      textContent = FadeTransition(
        opacity: textFade!,
        child: SlideTransition(position: textSlide!, child: textContent),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenPaddingH,
      ),
      child: Column(
        children: [
          Expanded(
            flex: 56,
            child: _IllustrationCard(data: data),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Expanded(
            flex: 44,
            child: textContent,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration card
// ─────────────────────────────────────────────────────────────────────────────

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              data.accentColor.withValues(alpha: 0.13),
              data.secondaryColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: data.accentColor.withValues(alpha: 0.18),
            width: 1.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -constraints.maxWidth * 0.18,
              right: -constraints.maxWidth * 0.15,
              child: _Blob(
                size: constraints.maxWidth * 0.55,
                color: data.accentColor.withValues(alpha: 0.07),
              ),
            ),
            Positioned(
              bottom: -constraints.maxWidth * 0.14,
              left: -constraints.maxWidth * 0.12,
              child: _Blob(
                size: constraints.maxWidth * 0.42,
                color: data.secondaryColor.withValues(alpha: 0.07),
              ),
            ),
            Center(
              child: SizedBox(
                width: constraints.maxWidth * 0.75,
                height: constraints.maxHeight * 0.72,
                child: CustomPaint(painter: data.painter),
              ),
            ),
            Positioned(
              top: AppConstants.spacingMd,
              left: AppConstants.spacingMd,
              child: _AppBadge(color: data.accentColor),
            ),
          ],
        ),
      );
    });
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _AppBadge extends StatelessWidget {
  const _AppBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight_takeoff_rounded, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            'Tripromio',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text block
// ─────────────────────────────────────────────────────────────────────────────

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: data.accentColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text(
          data.title,
          style: GoogleFonts.nunito(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.18,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text(
          data.subtitle,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom controls
// ─────────────────────────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.pageCount,
    required this.currentPage,
    required this.isLastPage,
    required this.accentColor,
    required this.onNext,
  });

  final int pageCount;
  final int currentPage;
  final bool isLastPage;
  final Color accentColor;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPaddingH,
        AppConstants.spacingMd,
        AppConstants.screenPaddingH,
        AppConstants.spacingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PageDots(
            count: pageCount,
            current: currentPage,
            accentColor: accentColor,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          _ActionButton(
            label: isLastPage ? 'Get Started' : 'Next',
            accentColor: accentColor,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page dots
// ─────────────────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.current,
    required this.accentColor,
  });

  final int count;
  final int current;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: AppConstants.animationNormal,
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? accentColor
                : accentColor.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: AppConstants.animationNormal,
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.accentColor,
                widget.accentColor.withValues(alpha: 0.78),
              ],
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.38),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppConstants.animationFast,
                child: Text(
                  widget.label,
                  key: ValueKey(widget.label),
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Custom illustration painters
// All drawn with pure Flutter — no image assets required.
// When real design assets arrive, swap each CustomPaint + painter with an
// Image.asset() or Lottie widget inside the existing _IllustrationCard.
// ═════════════════════════════════════════════════════════════════════════════

// ── Page 1: Compass / connections ─────────────────────────────────────────────

class _CompassPainter extends CustomPainter {
  const _CompassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) * 0.36;

    const accent = Color(0xFF5B6CF8);

    // Outer fill
    canvas.drawCircle(
        Offset(cx, cy), r, Paint()..color = accent.withValues(alpha: 0.10));
    // Outer stroke
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = accent.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // Second ring
    canvas.drawCircle(
        Offset(cx, cy),
        r * 1.22,
        Paint()
          ..color = accent.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Cross-hairs
    final hair = Paint()
      ..color = accent.withValues(alpha: 0.20)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), hair);
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), hair);

    // North needle
    final north = Path()
      ..moveTo(cx, cy - r * 0.75)
      ..lineTo(cx - 9, cy)
      ..lineTo(cx + 9, cy)
      ..close();
    canvas.drawPath(north, Paint()..color = accent);

    // South needle (muted)
    final south = Path()
      ..moveTo(cx, cy + r * 0.75)
      ..lineTo(cx - 9, cy)
      ..lineTo(cx + 9, cy)
      ..close();
    canvas.drawPath(
        south, Paint()..color = accent.withValues(alpha: 0.30));

    // Centre hub
    canvas.drawCircle(Offset(cx, cy), 7, Paint()..color = accent);
    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = Colors.white);

    // Cardinal dots
    final dot = Paint()..color = accent;
    canvas.drawCircle(Offset(cx, cy - r + 8), 4, dot);
    canvas.drawCircle(Offset(cx + r - 8, cy), 3, dot);
    canvas.drawCircle(Offset(cx, cy + r - 8), 3, dot);
    canvas.drawCircle(Offset(cx - r + 8, cy), 3, dot);

    // Companion avatars
    _avatar(canvas, Offset(cx + r * 1.45, cy - r * 0.50), 18,
        const Color(0xFFFFB347));
    _avatar(canvas, Offset(cx - r * 1.42, cy + r * 0.40), 15,
        const Color(0xFF3DAF8A));
    _avatar(canvas, Offset(cx + r * 0.45, cy + r * 1.40), 16,
        const Color(0xFFFF7B54));
  }

  void _avatar(Canvas canvas, Offset c, double radius, Color color) {
    canvas.drawCircle(
        c, radius, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(
        c,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // Head
    canvas.drawCircle(
        c.translate(0, -radius * 0.28), radius * 0.30, Paint()..color = color);
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: c.translate(0, radius * 0.32),
            width: radius * 0.72,
            height: radius * 0.52),
        const Radius.circular(6),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Page 2: Map / route ───────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const accent = Color(0xFF3DAF8A);

    // Card background
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.04, w * 0.88, h * 0.72),
      const Radius.circular(20),
    );
    canvas.drawRRect(card, Paint()..color = Colors.white);
    canvas.drawRRect(
        card,
        Paint()
          ..color = accent.withValues(alpha: 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Grid texture
    final grid = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (double x = w * 0.06; x < w * 0.94; x += 22) {
      canvas.drawLine(Offset(x, h * 0.04), Offset(x, h * 0.76), grid);
    }
    for (double y = h * 0.04; y < h * 0.76; y += 22) {
      canvas.drawLine(Offset(w * 0.06, y), Offset(w * 0.94, y), grid);
    }

    // Route shadow
    final route = Path()
      ..moveTo(w * 0.20, h * 0.60)
      ..cubicTo(w * 0.30, h * 0.28, w * 0.56, h * 0.68, w * 0.72, h * 0.22);
    canvas.drawPath(
        route,
        Paint()
          ..color = accent.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(
        route,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    _pin(canvas, Offset(w * 0.20, h * 0.60), accent);
    _pin(canvas, Offset(w * 0.72, h * 0.22), const Color(0xFFFF7B54));

    // Waypoint dot
    canvas.drawCircle(
        Offset(w * 0.47, h * 0.48), 7, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(w * 0.47, h * 0.48),
        7,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Info strip at bottom
    final info = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.78, w * 0.72, h * 0.16),
      const Radius.circular(12),
    );
    canvas.drawRRect(info, Paint()..color = accent);
    _bar(canvas, Offset(w * 0.22, h * 0.832), w * 0.24, h * 0.052,
        Colors.white.withValues(alpha: 0.40));
    _bar(canvas, Offset(w * 0.50, h * 0.832), w * 0.30, h * 0.052,
        Colors.white.withValues(alpha: 0.25));
  }

  void _pin(Canvas canvas, Offset tip, Color color) {
    const pinR = 10.0;
    final head = tip.translate(0, -pinR * 2.4);
    final tail = Path()
      ..moveTo(head.dx - 5, head.dy + pinR * 0.55)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(head.dx + 5, head.dy + pinR * 0.55)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);
    canvas.drawCircle(head, pinR, Paint()..color = color);
    canvas.drawCircle(
        head,
        pinR,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(head, pinR * 0.38, Paint()..color = Colors.white);
  }

  void _bar(Canvas canvas, Offset o, double w, double h, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx, o.dy, w, h),
        const Radius.circular(4),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Page 3: Shield / safety ───────────────────────────────────────────────────

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 8;
    const accent = Color(0xFFFF7B54);

    // Halo
    canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.44,
        Paint()..color = accent.withValues(alpha: 0.07));

    final sw = size.width * 0.50;
    final sh = size.height * 0.60;
    final st = cy - sh * 0.50;

    final shield = Path()
      ..moveTo(cx, st)
      ..lineTo(cx + sw / 2, st + sh * 0.18)
      ..lineTo(cx + sw / 2, st + sh * 0.55)
      ..quadraticBezierTo(cx + sw / 2, st + sh * 0.94, cx, st + sh)
      ..quadraticBezierTo(cx - sw / 2, st + sh * 0.94, cx - sw / 2, st + sh * 0.55)
      ..lineTo(cx - sw / 2, st + sh * 0.18)
      ..close();

    canvas.drawPath(shield, Paint()..color = accent.withValues(alpha: 0.12));
    canvas.drawPath(
        shield,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);

    // Inner decorative shield
    final inner = Path()
      ..moveTo(cx, st + 14)
      ..lineTo(cx + sw * 0.37, st + sh * 0.22)
      ..lineTo(cx + sw * 0.37, st + sh * 0.55)
      ..quadraticBezierTo(cx + sw * 0.37, st + sh * 0.86, cx, st + sh * 0.94)
      ..quadraticBezierTo(cx - sw * 0.37, st + sh * 0.86, cx - sw * 0.37, st + sh * 0.55)
      ..lineTo(cx - sw * 0.37, st + sh * 0.22)
      ..close();
    canvas.drawPath(inner, Paint()..color = accent.withValues(alpha: 0.07));

    // Checkmark
    final check = Path()
      ..moveTo(cx - 18, cy + 2)
      ..lineTo(cx - 4, cy + 16)
      ..lineTo(cx + 20, cy - 14);
    canvas.drawPath(
        check,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    // Rating badges
    _badge(canvas, Offset(cx - 50, cy + 70), accent);
    _badge(canvas, Offset(cx + 50, cy + 62), const Color(0xFF3DAF8A));

    // Verify badge top-right
    _verify(canvas, Offset(cx + sw * 0.47, st - 4), accent);
  }

  void _badge(Canvas canvas, Offset center, Color color) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 64, height: 26),
      const Radius.circular(13),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    _star(canvas, center.translate(-18, 0), 6, color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(center.dx - 5, center.dy - 4, 22, 5),
          const Radius.circular(3)),
      Paint()..color = color.withValues(alpha: 0.40),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(center.dx - 5, center.dy + 3, 14, 5),
          const Radius.circular(3)),
      Paint()..color = color.withValues(alpha: 0.25),
    );
  }

  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final r = i.isEven ? radius : radius * 0.45;
      final dx = center.dx + r * math.cos(angle);
      final dy = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _verify(Canvas canvas, Offset c, Color color) {
    canvas.drawCircle(
        c, 12, Paint()..color = color.withValues(alpha: 0.15));
    canvas.drawCircle(
        c,
        12,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    final check = Path()
      ..moveTo(c.dx - 5, c.dy + 1)
      ..lineTo(c.dx - 1, c.dy + 5)
      ..lineTo(c.dx + 6, c.dy - 4);
    canvas.drawPath(
        check,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
