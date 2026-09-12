import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/services/trip_service.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/trip_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MyTripsScreen
// ─────────────────────────────────────────────────────────────────────────────

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final _tripService = TripService();
  final _scrollController = ScrollController();

  List<TripModel> _trips = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tripService.dispose();
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
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final result = await _tripService.getMyTrips(page: 1);
      if (!mounted) return;
      setState(() {
        _trips = result.items;
        _hasMore = result.pagination.currentPage < result.pagination.lastPage;
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
    setState(() => _loadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final result = await _tripService.getMyTrips(page: nextPage);
      if (!mounted) return;
      setState(() {
        _trips.addAll(result.items);
        _currentPage = nextPage;
        _hasMore = result.pagination.currentPage < result.pagination.lastPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onTripTap(TripModel trip) {
    Navigator.of(context).pushNamed(
      AppRoutes.tripDetail,
      arguments: trip.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final topPad = MediaQuery.paddingOf(context).top;
    final botPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed(AppRoutes.createTrip);
          // Refresh list when returning from create
          if (mounted) _load();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
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
                Text(
                  'My Trips',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (!_loading && _trips.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusFull),
                    ),
                    child: Text(
                      '${_trips.length} trip${_trips.length == 1 ? '' : 's'}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _ErrorView(
                        message: _errorMessage!, onRetry: _load)
                    : _trips.isEmpty
                        ? _EmptyView(
                            onCreateTrip: () {
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.createTrip)
                                  .then((_) {
                                if (mounted) _load();
                              });
                            },
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _load,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(
                                AppConstants.screenPaddingH,
                                AppConstants.spacingMd,
                                AppConstants.screenPaddingH,
                                botPad + 80,
                              ),
                              itemCount: _trips.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _trips.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final trip = _trips[index];
                                final card =
                                    TripCardData.fromTripModel(trip);

                                return Column(
                                  children: [
                                    TripCard(
                                      data: card,
                                      onTap: () => _onTripTap(trip),
                                    ),
                                    // Status badge below card
                                    _TripStatusBadge(status: trip.status),
                                  ],
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

// ── Status badge ──────────────────────────────────────────────────────────────

class _TripStatusBadge extends StatelessWidget {
  const _TripStatusBadge({required this.status});
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
        label = '● Draft';
      case TripStatus.published:
        bgColor = AppColors.success.withValues(alpha: 0.12);
        textColor = AppColors.success;
        label = '● Published';
      case TripStatus.ongoing:
        bgColor = AppColors.info.withValues(alpha: 0.12);
        textColor = AppColors.info;
        label = '● Ongoing';
      case TripStatus.completed:
        bgColor = AppColors.textSecondaryLight.withValues(alpha: 0.12);
        textColor = AppColors.textSecondaryLight;
        label = '● Completed';
      case TripStatus.cancelled:
        bgColor = AppColors.error.withValues(alpha: 0.12);
        textColor = AppColors.error;
        label = '● Cancelled';
      case TripStatus.unknown:
        bgColor = AppColors.textSecondaryLight.withValues(alpha: 0.12);
        textColor = AppColors.textSecondaryLight;
        label = '● Unknown';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          ),
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreateTrip});
  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flight_takeoff_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'No trips yet',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first trip and find companions!',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          ElevatedButton.icon(
            onPressed: onCreateTrip,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              textStyle:
                  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
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
