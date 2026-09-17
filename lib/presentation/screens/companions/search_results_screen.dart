import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/companion_model.dart';
import '../../../data/services/companion_service.dart';
import '../../../routes/app_routes.dart';
import 'find_companions_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CompanionDiscoveryScreen — replaces SearchResultsScreen for /discover route
// ─────────────────────────────────────────────────────────────────────────────

/// Real companion discovery feed powered by GET /api/companions.
///
/// Receives optional [CompanionSearchArgs] from [FindCompanionsScreen].
/// Supports: initial load, pull-to-refresh, infinite scroll / load-more,
/// loading / empty / error / pagination-error states.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _service = CompanionService();
  final _scrollController = ScrollController();

  List<CompanionModel> _companions = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  String? _paginationError;

  CompanionSearchArgs? get _args {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is CompanionSearchArgs ? args : null;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _companions.isEmpty && _errorMessage == null) {
      _load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _paginationError = null;
      _currentPage = 1;
      _companions = [];
    });

    try {
      final args = _args;
      final result = await _service.getCompanions(
        page: 1,
        destination: args?.destination,
        startDate: args?.dateRange?.start,
        endDate: args?.dateRange?.end,
        travelStyle: args?.travelStyle,
        sort: args?.sort,
      );

      if (!mounted) return;
      setState(() {
        _companions = result.items;
        _hasMore = result.pagination.hasMore;
        _loading = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No internet connection. Please retry.';
        _loading = false;
      });
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Session expired. Please log in again.';
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });

    try {
      final nextPage = _currentPage + 1;
      final args = _args;
      final result = await _service.getCompanions(
        page: nextPage,
        destination: args?.destination,
        startDate: args?.dateRange?.start,
        endDate: args?.dateRange?.end,
        travelStyle: args?.travelStyle,
        sort: args?.sort,
      );

      if (!mounted) return;
      setState(() {
        _companions.addAll(result.items);
        _currentPage = nextPage;
        _hasMore = result.pagination.hasMore;
        _loadingMore = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = 'No internet. Tap to retry.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = 'Failed to load more. Tap to retry.';
      });
    }
  }

  void _openDetail(CompanionModel companion) {
    Navigator.of(context).pushNamed(
      AppRoutes.companionDetail,
      arguments: companion,
    );
  }

  String _buildSubtitle(CompanionSearchArgs? args) {
    final parts = <String>[];
    if (args?.destination != null && args!.destination!.isNotEmpty) {
      parts.add(args.destination!);
    }
    if (args?.travelStyle != null) {
      parts.add(args!.travelStyle!.replaceAll('_', ' ').toUpperCase()[0] +
          args.travelStyle!.replaceAll('_', ' ').substring(1));
    }
    if (parts.isEmpty) return 'All companions';
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final topPad = MediaQuery.paddingOf(context).top;
    final args = _args;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              AppConstants.screenPaddingH,
              topPad + AppConstants.spacingMd,
              AppConstants.screenPaddingH,
              AppConstants.spacingLg,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1628), Color(0xFF0F3460)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppConstants.radiusXl),
                bottomRight: Radius.circular(AppConstants.radiusXl),
              ),
            ),
            child: Row(
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
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 17),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Travel Companions',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _buildSubtitle(args),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    // Go back to filter screen
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _ErrorState(
                        message: _errorMessage!,
                        onRetry: _load,
                      )
                    : _companions.isEmpty
                        ? _EmptyState(
                            hasFilters: args != null &&
                                (args.destination != null ||
                                    args.travelStyle != null ||
                                    args.dateRange != null),
                            onClearFilters: () {
                              Navigator.of(context).pop();
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.screenPaddingH,
                                vertical: AppConstants.spacingMd,
                              ),
                              itemCount:
                                  _companions.length + (_hasMore || _paginationError != null ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _companions.length) {
                                  // Pagination footer
                                  if (_paginationError != null) {
                                    return _PaginationError(
                                      message: _paginationError!,
                                      onRetry: _loadMore,
                                    );
                                  }
                                  return _PaginationLoader(
                                    isLoading: _loadingMore,
                                  );
                                }

                                return CompanionCard(
                                  companion: _companions[index],
                                  onTap: () => _openDetail(_companions[index]),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CompanionCard — reusable companion card widget
// ─────────────────────────────────────────────────────────────────────────────

/// Displays discovery-safe companion info. Does NOT show email, budget,
/// profile_completion, or any unsupported backend fields.
class CompanionCard extends StatelessWidget {
  const CompanionCard({
    super.key,
    required this.companion,
    required this.onTap,
  });

  final CompanionModel companion;
  final VoidCallback onTap;

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
    final photoUrl = _resolvePhotoUrl(companion.profilePhotoUrl);
    final styleLabel = _styleLabels[companion.travelStyle] ?? companion.travelStyle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar + name/location ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  _Avatar(photoUrl: photoUrl, name: companion.name, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companion.name,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        if (companion.location != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  companion.location!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (styleLabel != null) ...[
                          const SizedBox(height: 6),
                          _StyleChip(label: styleLabel),
                        ],
                      ],
                    ),
                  ),
                  // Chevron
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondaryLight, size: 22),
                ],
              ),
            ),

            // ── Bio ──────────────────────────────────────────────────────────
            if (companion.bio != null && companion.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  companion.bio!,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ── Interests ────────────────────────────────────────────────────
            if (companion.interests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: companion.interests
                      .take(4)
                      .map((i) => _InterestChip(name: i.name))
                      .toList(),
                ),
              ),

            // ── Preferred Destinations ────────────────────────────────────────
            if (companion.preferredDestinations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        size: 14, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        companion.preferredDestinations
                            .take(3)
                            .map((d) => d.destination)
                            .join(' · '),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
    required this.name,
    required this.size,
  });

  final String? photoUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _FallbackAvatar(initial: initial, size: size),
        ),
      );
    }
    return _FallbackAvatar(initial: initial, size: size);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initial, required this.size});
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.nunito(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        name,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
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
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.textSecondaryLight),
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters, required this.onClearFilters});
  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No companions found',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters to discover more travel partners.'
                  : 'No discoverable companions available at this time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Adjust Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaginationLoader extends StatelessWidget {
  const _PaginationLoader({required this.isLoading});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _PaginationError extends StatelessWidget {
  const _PaginationError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves a profile photo URL from the backend.
/// Handles null, relative paths, and absolute URLs.
String? _resolvePhotoUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  // Relative path — not expected from backend but guard anyway.
  return null;
}
