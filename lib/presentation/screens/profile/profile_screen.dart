import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/preferred_destination_model.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

// ─── Photo URL helper ────────────────────────────────────────────────────────

/// Resolves a profile photo URL from the backend to an absolute URL.
///
/// The backend may return:
///   a) A full URL: https://... (production) or http://... (local dev) → use as-is
///   b) A relative path: storage/... or profile_photos/... → prepend the
///      backend host (http://10.0.2.2:8000 on Android emulator).
///
/// This function never throws; it returns null if [raw] is null/empty.
String? resolvePhotoUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  // DEBUG LOG AS REQUESTED
  print('[DEBUG-resolvePhotoUrl] raw input: $raw');

  String processed = raw;
  if (processed.startsWith('http://localhost:')) {
    processed = processed.replaceFirst('http://localhost:', 'http://10.0.2.2:');
    print('[DEBUG-resolvePhotoUrl] converted localhost to 10.0.2.2: $processed');
  } else if (processed.startsWith('http://127.0.0.1:')) {
    processed = processed.replaceFirst('http://127.0.0.1:', 'http://10.0.2.2:');
    print('[DEBUG-resolvePhotoUrl] converted 127.0.0.1 to 10.0.2.2: $processed');
  }

  if (processed.startsWith('http://') || processed.startsWith('https://')) {
    print('[DEBUG-resolvePhotoUrl] final url: $processed');
    return processed;
  }
  
  // Relative path — prepend the Laravel dev host.
  const devHost = 'http://10.0.2.2:8000';
  final path = processed.startsWith('/') ? processed : '/$processed';
  final finalUrl = '$devHost$path';
  print('[DEBUG-resolvePhotoUrl] final url (relative prepended): $finalUrl');
  return finalUrl;
}

// ─── Max photo file size ─────────────────────────────────────────────────────
const int _maxPhotoBytes = 5 * 1024 * 1024; // 5 MB

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

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
  final _authService = AuthService();
  final _picker = ImagePicker();

  UserModel? _user;
  bool _loading = true;
  bool _photoUploading = false;
  bool _isLoggingOut = false;
  String? _errorMessage;
  List<PreferredDestinationModel>? _destinations;
  String? _destinationsError;

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
      _destinationsError = null;
    });
    
    try {
      // Load user profile
      final user = await _service.getProfile();
      
      // Try to load destinations, but don't fail profile if it fails
      List<PreferredDestinationModel>? destList;
      String? destErr;
      try {
        destList = await _service.getPreferredDestinations();
      } catch (e) {
        destErr = 'Failed to load destinations.';
      }
      
      if (!mounted) return;
      setState(() {
        _user = user;
        _destinations = destList;
        _destinationsError = destErr;
      });
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'An unexpected error occurred: ');
      debugPrint('Unexpected error in profile _load: \n');
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


  Future<void> _openEditInterests() async {
    final updated = await Navigator.of(context).pushNamed(
      AppRoutes.editInterests,
      arguments: _user?.interests ?? [],
    );
    if (updated is UserModel && mounted) {
      setState(() => _user = updated);
    }
  }


  Future<void> _openDestinations() async {
    final updated = await Navigator.of(context).pushNamed(
      AppRoutes.preferredDestinations,
    );
    if (updated is List<PreferredDestinationModel> && mounted) {
      setState(() => _destinations = updated);
    }
  }

  // ── Photo edit bottom sheet ───────────────────────────────────────────────


  /// Shows the bottom sheet with "Choose Photo" / "Remove Photo" / "Cancel".
  void _showPhotoOptions() {
    if (_photoUploading) return;
    final hasPhoto =
        _user?.profile?.profilePhotoUrl?.isNotEmpty ?? false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoOptionsSheet(
        hasPhoto: hasPhoto,
        onChoose: _pickAndUpload,
        onRemove: _confirmRemove,
      ),
    );
  }

  /// Opens the gallery picker, validates, then uploads.
  Future<void> _pickAndUpload() async {
    Navigator.of(context).pop(); // close bottom sheet

    // Pick from gallery only — no camera.
    XFile? picked;
    try {
      picked = await _picker.pickImage(source: ImageSource.gallery);
    } catch (_) {
      // User denied permission or picker failed.
      if (mounted) {
        _showSnack('Could not open gallery. Please check app permissions.');
      }
      return;
    }

    if (picked == null) return; // User cancelled — do nothing.

    // ── File size check ──────────────────────────────────────────────────────
    final file = File(picked.path);
    final fileSize = await file.length();
    if (fileSize > _maxPhotoBytes) {
      if (mounted) {
        _showSnack('Please choose an image smaller than 5 MB.');
      }
      return;
    }

    // ── Upload ───────────────────────────────────────────────────────────────
    setState(() => _photoUploading = true);
    try {
      final updated = await _service.uploadProfilePhoto(picked.path);
      if (!mounted) return;
      
      // Evict old image from cache if URL didn't change
      final newUrl = resolvePhotoUrl(updated.profile?.profilePhotoUrl);
      if (newUrl != null) {
        await NetworkImage(newUrl).evict();
      }
      
      setState(() => _user = updated);
      _showSnack('Profile photo updated!', isSuccess: true);
    } on ValidationException catch (e) {
      final msgs = (e.errors?.values.expand((v) => v).join('\n')) ?? e.message;
      if (mounted) _showSnack(msgs);
    } on NetworkException {
      if (mounted) {
        _showSnack(
            'No internet connection. Please check your connection and retry.');
      }
    } on ServerException catch (e) {
      if (mounted) _showSnack(e.message);
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  /// Asks for confirmation then calls DELETE /api/profile/photo.
  Future<void> _confirmRemove() async {
    Navigator.of(context).pop(); // close bottom sheet

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text(
            'Your profile photo will be removed. You can upload a new one anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _photoUploading = true);
    try {
      final updated = await _service.deleteProfilePhoto();
      if (!mounted) return;
      setState(() => _user = updated);
      _showSnack('Profile photo removed.', isSuccess: true);
    } on NetworkException {
      if (mounted) {
        _showSnack('No internet connection. Please retry.');
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of Tripromio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Log out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    
    // AuthService.logout() calls API, catches errors, and guarantees token deletion.
    await _authService.logout();

    if (!mounted) return;
    
    // Clear navigation stack and go to Login.
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
              : Stack(
                  children: [
                    _ProfileBody(
                      user: _user!,
                      photoUploading: _photoUploading,
                      onEdit: _openEdit,
                      onPhotoEdit: _showPhotoOptions,
                      onEditInterests: _openEditInterests,
                      onEditDestinations: _openDestinations,
                      destinations: _destinations,
                      destinationsError: _destinationsError,
                      onLogout: _confirmLogout,
                    ),
                    if (_isLoggingOut)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo options bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoOptionsSheet extends StatelessWidget {
  const _PhotoOptionsSheet({
    required this.hasPhoto,
    required this.onChoose,
    required this.onRemove,
  });

  final bool hasPhoto;
  final VoidCallback onChoose;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Profile Photo',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          _SheetOption(
            icon: Icons.photo_library_rounded,
            label: 'Choose Photo',
            onTap: onChoose,
          ),
          if (hasPhoto) ...[
            const Divider(height: 1),
            _SheetOption(
              icon: Icons.delete_outline_rounded,
              label: 'Remove Photo',
              onTap: onRemove,
              color: AppColors.error,
            ),
          ],
          const Divider(height: 1),
          _SheetOption(
            icon: Icons.close_rounded,
            label: 'Cancel',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimaryLight;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
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
  const _ProfileBody({
    required this.user,
    required this.photoUploading,
    required this.onEdit,
    required this.onPhotoEdit,
    required this.onEditInterests,
    required this.onEditDestinations,
    required this.onLogout,
    required this.destinations,
    required this.destinationsError,
  });

  final UserModel user;
  final bool photoUploading;
  final VoidCallback onEdit;
  final VoidCallback onPhotoEdit;
  final VoidCallback onEditInterests;
  final VoidCallback onEditDestinations;
  final VoidCallback onLogout;
  final List<PreferredDestinationModel>? destinations;
  final String? destinationsError;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header / hero
        SliverToBoxAdapter(
          child: _ProfileHeader(
            user: user,
            photoUploading: photoUploading,
            onEdit: onEdit,
            onPhotoEdit: onPhotoEdit,
          ),
        ),

        // Profile completion bar
        if (user.profileCompletion < 100)
          SliverToBoxAdapter(
            child: _CompletionBar(percent: user.profileCompletion),
          ),

        // Sections
        SliverToBoxAdapter(child: _AboutSection(user: user)),
        SliverToBoxAdapter(child: _TravelSection(user: user, onEditInterests: onEditInterests)),
        SliverToBoxAdapter(child: _DestinationsSection(
          destinations: destinations, 
          error: destinationsError, 
          onEdit: onEditDestinations,
        )),
        SliverToBoxAdapter(child: _BudgetSection(user: user)),
        SliverToBoxAdapter(child: _AccountSection(onLogout: onLogout)),

        // Bottom breathing room
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header hero  (photo avatar with edit overlay)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.photoUploading,
    required this.onEdit,
    required this.onPhotoEdit,
  });

  final UserModel user;
  final bool photoUploading;
  final VoidCallback onEdit;
  final VoidCallback onPhotoEdit;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final photoUrl = resolvePhotoUrl(user.profile?.profilePhotoUrl);

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

          // Avatar with camera-edit overlay
          GestureDetector(
            onTap: onPhotoEdit,
            child: Stack(
              children: [
                // ── Photo or initials ──────────────────────────────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: photoUrl == null
                        ? const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
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
                  child: ClipOval(
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, obj, err) => _InitialsAvatar(
                              initial: initial,
                            ),
                          )
                        : _InitialsAvatar(initial: initial),
                  ),
                ),

                // ── Upload loading overlay ─────────────────────────────────
                if (photoUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Camera badge ───────────────────────────────────────────
                if (!photoUploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
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

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
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
  const _TravelSection({required this.user, required this.onEditInterests});

  final UserModel user;
  final VoidCallback onEditInterests;

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
      title: 'Travel Style & Interests',
      icon: Icons.explore_rounded,
      onEdit: onEditInterests,
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
                interests.map((i) => _Tag(label: i.name)).toList(),
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
    this.onEdit,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final VoidCallback? onEdit;

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
              const Spacer(),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.textSecondaryLight,
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


// ─────────────────────────────────────────────────────────────────────────────
// Preferred Destinations Section
// ─────────────────────────────────────────────────────────────────────────────

class _DestinationsSection extends StatelessWidget {
  const _DestinationsSection({
    required this.destinations,
    required this.error,
    required this.onEdit,
  });

  final List<PreferredDestinationModel>? destinations;
  final String? error;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _Section(
        title: 'Preferred Destinations',
        icon: Icons.place_rounded,
        onEdit: onEdit,
        children: [
          Text(
            error!,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.error,
            ),
          ),
        ],
      );
    }

    if (destinations == null || destinations!.isEmpty) {
      return _Section(
        title: 'Preferred Destinations',
        icon: Icons.place_rounded,
        onEdit: onEdit,
        children: [
          Text(
            'No destinations added yet.',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return _Section(
      title: 'Preferred Destinations',
      icon: Icons.place_rounded,
      onEdit: onEdit,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: destinations!.map((d) => _Tag(label: d.destination)).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Settings Section (Logout)
// ─────────────────────────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimaryLight.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Log out',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.error, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
