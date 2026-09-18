import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/companion_model.dart';
import '../../../data/services/connection_service.dart';
import '../../../routes/app_routes.dart';
import '../profile/profile_screen.dart' show resolvePhotoUrl;

class MyConnectionsScreen extends StatefulWidget {
  const MyConnectionsScreen({super.key});

  @override
  State<MyConnectionsScreen> createState() => _MyConnectionsScreenState();
}

class _MyConnectionsScreenState extends State<MyConnectionsScreen> {
  final _service = ConnectionService();
  final _scrollController = ScrollController();

  List<CompanionModel> _connections = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _paginationError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
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
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _paginationError = null;
      _currentPage = 1;
      _connections = [];
    });

    try {
      final result = await _service.getMyConnections(page: 1);
      if (!mounted) return;
      setState(() {
        _connections = result.items;
        _hasMore = result.pagination.hasMore;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _error = 'Session expired. Please log in again.';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred.';
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
      final result = await _service.getMyConnections(page: nextPage);
      if (!mounted) return;
      setState(() {
        // Prevent duplicates
        final newItems = result.items.where((newItem) => 
            !_connections.any((existing) => existing.id == newItem.id)).toList();
        
        _connections.addAll(newItems);
        _currentPage = nextPage;
        _hasMore = result.pagination.hasMore;
        _loadingMore = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _paginationError = e.message;
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
              AppConstants.screenPaddingH,
              topPad + AppConstants.spacingMd,
              AppConstants.screenPaddingH,
              AppConstants.spacingMd,
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
                Text(
                  'My Connections',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    if (_connections.isEmpty) {
      return _EmptyState(
        icon: Icons.handshake_rounded,
        message: 'No connections yet.',
        hint: 'You can discover travelers and send connection requests from Find Companions.',
        onRefresh: _load,
        onFindCompanions: () {
          Navigator.of(context).pushNamed(AppRoutes.findCompanions);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingH,
          vertical: AppConstants.spacingMd,
        ),
        itemCount: _connections.length + (_hasMore || _paginationError != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _connections.length) {
            if (_paginationError != null) {
              return _PaginationError(
                message: _paginationError!,
                onRetry: _loadMore,
              );
            }
            return _PaginationLoader(isLoading: _loadingMore);
          }

          final connection = _connections[index];
          return _ConnectionCard(
            companion: connection,
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.companionDetail,
                arguments: connection,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connection Card
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.companion,
    required this.onTap,
  });

  final CompanionModel companion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photoUrl = resolvePhotoUrl(companion.profilePhotoUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              companion.location!,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (companion.travelStyle != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                        ),
                        child: Text(
                          _formatTravelStyle(companion.travelStyle!),
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                    if (companion.bio != null && companion.bio!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        companion.bio!,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHintLight, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTravelStyle(String style) {
    const labels = {
      'adventure': 'Adventure',
      'backpacking': 'Backpacking',
      'budget': 'Budget',
      'luxury': 'Luxury',
      'relaxed': 'Relaxed',
      'road_trip': 'Road Trip',
      'nature': 'Nature',
      'cultural': 'Cultural',
    };
    return labels[style] ?? (style.isEmpty ? '' : style[0].toUpperCase() + style.substring(1));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets (re-implemented cleanly for this screen)
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
          errorBuilder: (context, error, stackTrace) =>
              _FallbackAvatar(initial: initial, size: size),
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
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
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
                size: 48, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),
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
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.hint,
    required this.onRefresh,
    required this.onFindCompanions,
  });

  final IconData icon;
  final String message;
  final String hint;
  final VoidCallback onRefresh;
  final VoidCallback onFindCompanions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                child: Icon(icon, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onFindCompanions,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Find Companions'),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
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
                width: 26,
                height: 26,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
