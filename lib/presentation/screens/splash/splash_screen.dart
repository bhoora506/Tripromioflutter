import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

/// Tripromio splash screen — plays [_kSplashAsset] full-screen, resolves the
/// auth destination concurrently, then navigates exactly once.
///
/// Fallback behaviour (video init failure):
///   Shows the original deep-navy branded background and navigates after
///   [_kFallbackDuration], mirroring the previous splash timing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// ── Constants ────────────────────────────────────────────────────────────────

const String _kSplashAsset = 'assets/videos/tripromio_splash.mp4';

/// Minimum time on screen when the video cannot be loaded.
const Duration _kFallbackDuration = Duration(milliseconds: 2200);

// ── State ────────────────────────────────────────────────────────────────────

class _SplashScreenState extends State<SplashScreen> {
  // ── Video ────────────────────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _videoReady = false;   // controller initialised & playback started
  bool _videoFailed = false;  // could not initialise the video

  // ── Services ─────────────────────────────────────────────────────────────
  final _tokenStorage = TokenStorage();
  final _authService  = AuthService();

  // ── Navigation guard ─────────────────────────────────────────────────────
  bool _navigated = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Edge-to-edge: transparent status bar, light icons on dark video.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _startSequence();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoEvent);
    _videoController?.dispose();
    _authService.dispose();
    super.dispose();
  }

  // ── Sequence ─────────────────────────────────────────────────────────────

  /// Kicks off the video and the auth check in parallel. Navigation fires
  /// when both are done (or when a fallback timer expires on video failure).
  Future<void> _startSequence() async {
    // Auth check starts immediately — it runs concurrently with video loading.
    final authFuture = _resolveAuthDestination();

    // Try to initialise the video.
    bool videoOk = false;
    try {
      final ctrl = VideoPlayerController.asset(_kSplashAsset);
      _videoController = ctrl;

      await ctrl.initialize();

      if (!mounted) return;

      await ctrl.setLooping(false);
      await ctrl.setVolume(0.0); // muted — the video is a silent intro

      ctrl.addListener(_onVideoEvent);

      if (mounted) setState(() => _videoReady = true);
      await ctrl.play();
      videoOk = true;
    } catch (_) {
      // Video unavailable or codec unsupported — fall through to fallback.
      if (mounted) setState(() => _videoFailed = true);
    }

    // ── Determine when we are "done" on the video side ────────────────────
    final Future<void> videoCompleteFuture;
    if (videoOk && _videoController != null) {
      // Wait for the video to finish playing.
      videoCompleteFuture = _videoPlaybackComplete();
    } else {
      // Fallback: honour the minimum branded duration.
      videoCompleteFuture = Future<void>.delayed(_kFallbackDuration);
    }

    // Navigate when BOTH auth and video/fallback are done.
    final results = await Future.wait([authFuture, videoCompleteFuture]);
    if (!mounted || _navigated) return;
    _navigated = true;

    final destination = results[0] as String;
    Navigator.of(context).pushReplacementNamed(destination);
  }

  /// Returns a [Future] that completes when the video reaches its end.
  Future<void> _videoPlaybackComplete() {
    final ctrl = _videoController;
    if (ctrl == null) return Future<void>.value();

    // Polling loop — lightweight 100 ms tick, stops as soon as playback ends.
    return Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return false; // widget disposed — abort
      final v = ctrl.value;
      if (v.hasError) return false;
      final dur = v.duration;
      final pos = v.position;
      // Stop polling once we reach (or pass) the last 50 ms of the video.
      if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 50)) {
        return false;
      }
      return true; // keep waiting
    });
  }

  /// Listener on [VideoPlayerController] — triggers rebuilds so the
  /// [_VideoLayer] fades in as soon as the first frame is ready.
  void _onVideoEvent() {
    if (!mounted) return;
    setState(() {});
  }

  // ── Auth resolution (unchanged from previous implementation) ─────────────

  /// Decision tree:
  ///   1. No stored token          → onboarding (first time) or login
  ///   2. Token + /me OK           → Home (authenticated)
  ///   3. Token + /me 401          → delete token → login
  ///   4. Token + network/server   → login (token preserved for next launch)
  Future<String> _resolveAuthDestination() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      final seenOnboarding = await _tokenStorage.hasSeenOnboarding();
      return seenOnboarding ? AppRoutes.login : AppRoutes.onboarding;
    }

    try {
      await _authService.getCurrentUser();
      return AppRoutes.home;
    } on UnauthorizedException {
      await _tokenStorage.deleteToken();
      return AppRoutes.login;
    } on NetworkException {
      return AppRoutes.login;
    } on ApiException {
      return AppRoutes.login;
    } catch (_) {
      return AppRoutes.login;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Black base prevents any white flash before layers paint.
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: fallback branded background (always present) ──────
          const _SplashBackground(),

          // ── Layer 2: video (fades in once first frame is rendered) ─────
          if (!_videoFailed && _videoController != null)
            _VideoLayer(
              controller: _videoController!,
              ready: _videoReady,
            ),
        ],
      ),
    );
  }
}

// ── Video layer ───────────────────────────────────────────────────────────────

class _VideoLayer extends StatelessWidget {
  const _VideoLayer({required this.controller, required this.ready});

  final VideoPlayerController controller;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final initialized = controller.value.isInitialized;
    if (!initialized) return const SizedBox.shrink();

    final videoAspect = controller.value.aspectRatio;

    return AnimatedOpacity(
      opacity: ready ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: SizedBox.expand(
        child: FittedBox(
          // BoxFit.cover: fills the screen, preserving aspect ratio.
          // Any slight overflow is clipped — no distortion, no black bars.
          fit: BoxFit.cover,
          child: SizedBox(
            // Give FittedBox a concrete size to scale from (1000 px base).
            width: videoAspect * 1000,
            height: 1000,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

// ── Fallback branded background ──────────────────────────────────────────────

/// Exact replica of the original splash gradient — shown while the video
/// loads and as a permanent fallback if it cannot be initialised.
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
      child: Center(
        child: Opacity(
          opacity: 0.25,
          child: Icon(
            Icons.flight_takeoff_rounded,
            size: 80,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

