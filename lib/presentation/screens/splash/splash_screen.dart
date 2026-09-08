import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

/// Production splash screen for Tripromio.
///
/// Lifecycle:
///   1. Screen mounts → [AnimationController] starts.
///   2. Logo fades + scales in over 800 ms.
///   3. Tagline fades in 300 ms after logo.
///   4. After a total of 2 200 ms the screen navigates to [AppRoutes.onboarding].
///
/// No business logic lives here. Navigation is the only side-effect.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers are intentionally kept separate so the auth check and
  // the animation can run concurrently via [Future.wait].
  late final AnimationController _logoController;
  late final AnimationController _taglineController;

  // ── Animations ────────────────────────────────────────────────────────────
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;

  // ── Services ──────────────────────────────────────────────────────────────
  final _tokenStorage = TokenStorage();
  final _authService = AuthService();

  // ── Timing constants ──────────────────────────────────────────────────────
  static const Duration _logoDuration = Duration(milliseconds: 800);
  static const Duration _taglineDelay = Duration(milliseconds: 500);
  static const Duration _taglineDuration = Duration(milliseconds: 500);
  static const Duration _totalSplashDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();

    // Keep status bar transparent so the gradient bleeds edge-to-edge.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Logo controller — fade + subtle scale up.
    _logoController = AnimationController(
      vsync: this,
      duration: _logoDuration,
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Tagline controller — delayed pure fade-in.
    _taglineController = AnimationController(
      vsync: this,
      duration: _taglineDuration,
    );

    _taglineFade = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );

    _startSequence();
  }


  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    _authService.dispose();
    super.dispose();
  }

  // ── Auth-state resolution ─────────────────────────────────────────────────

  /// Runs the splash animation and auth check **in parallel**, then navigates
  /// exactly once when both are done.  This prevents any UI flicker.
  Future<void> _startSequence() async {
    // Kick off animation immediately.
    _logoController.forward();

    await Future<void>.delayed(_taglineDelay);
    if (!mounted) return;
    _taglineController.forward();

    // Run the remaining animation time and the auth check concurrently.
    // The navigation waits for whichever finishes last.
    final authDestFuture = _resolveAuthDestination();
    final minSplashFuture = Future<void>.delayed(
      _totalSplashDuration - _taglineDelay,
    );

    final results = await Future.wait([authDestFuture, minSplashFuture]);
    if (!mounted) return;

    final destination = results[0] as String;
    Navigator.of(context).pushReplacementNamed(destination);
  }

  /// Determines the correct post-splash route based on auth state.
  ///
  /// Decision tree:
  ///   1. No stored token          → show onboarding (first time) or login
  ///   2. Token + /me OK           → Home (authenticated)
  ///   3. Token + /me 401          → delete token → login
  ///   4. Token + network/server   → login (token preserved for next launch)
  Future<String> _resolveAuthDestination() async {
    final token = await _tokenStorage.getToken();

    // ── Case 1: No token ────────────────────────────────────────────────────
    if (token == null || token.isEmpty) {
      final seenOnboarding = await _tokenStorage.hasSeenOnboarding();
      return seenOnboarding ? AppRoutes.login : AppRoutes.onboarding;
    }

    // ── Cases 2-4: Token exists — verify with backend ───────────────────────
    try {
      await _authService.getCurrentUser();
      // Case 2: /auth/me succeeded → authenticated.
      return AppRoutes.home;
    } on UnauthorizedException {
      // Case 3: Token revoked/expired → clean up.
      await _tokenStorage.deleteToken();
      return AppRoutes.login;
    } on NetworkException {
      // Case 4: Server unreachable — keep token, let user retry later.
      // Send to login so they can manually trigger the auth check again
      // (they can log in, which will refresh the token).
      return AppRoutes.login;
    } on ApiException {
      // Unexpected API error (5xx etc.) — safe fallback, keep token.
      return AppRoutes.login;
    } catch (_) {
      // Unknown error — safe fallback, keep token.
      return AppRoutes.login;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      // Prevent the scaffold from painting over our full-bleed gradient.
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient ──────────────────────────────────────────
          const _SplashBackground(),

          // ── Decorative travel orbs ───────────────────────────────────────
          _TravelOrbs(screenSize: size),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Push branding into the upper-centre third.
                SizedBox(height: size.height * 0.28),

                // ── Brand mark ─────────────────────────────────────────────
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: const _BrandMark(),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Tagline ────────────────────────────────────────────────
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Find your travel companion',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const Spacer(),

                // ── Loading indicator ──────────────────────────────────────
                FadeTransition(
                  opacity: _taglineFade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Full-screen deep-blue gradient — the base of the splash.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1628), // very dark navy
            Color(0xFF0D2140), // deep ocean blue
            Color(0xFF0F3460), // rich midnight blue
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Decorative translucent orbs suggesting a globe / travel aesthetic.
/// Pure Flutter drawing — no assets required.
class _TravelOrbs extends StatelessWidget {
  const _TravelOrbs({required this.screenSize});

  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: screenSize,
      painter: _OrbPainter(),
    );
  }
}

class _OrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Large primary orb — top-right.
    paint.color = AppColors.primary.withValues(alpha: 0.12);
    canvas.drawCircle(
      Offset(size.width * 1.05, size.height * -0.05),
      size.width * 0.65,
      paint,
    );

    // Medium accent orb — bottom-left.
    paint.color = AppColors.accent.withValues(alpha: 0.09);
    canvas.drawCircle(
      Offset(size.width * -0.1, size.height * 1.05),
      size.width * 0.55,
      paint,
    );

    // Small highlight orb — centre-left.
    paint.color = AppColors.primaryLight.withValues(alpha: 0.07);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.45),
      size.width * 0.28,
      paint,
    );

    // Thin arc lines suggesting latitude/longitude — globe feel.
    _drawGlobeArcs(canvas, size);
  }

  void _drawGlobeArcs(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.06);

    final center = Offset(size.width * 1.05, size.height * -0.05);
    final baseRadius = size.width * 0.65;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, baseRadius + (i * 28.0), paint);
    }

    // Two diagonal arc strokes for longitude effect.
    final path = Path();
    path.addArc(
      Rect.fromCenter(
        center: center,
        width: baseRadius * 1.6,
        height: baseRadius * 2.4,
      ),
      math.pi * 0.6,
      math.pi * 0.8,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Image.asset(
            'assets/images/tripromio_logo.jpg',
            width: 180,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
