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
import 'find_companions_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchResultsScreen (Discover)
// ─────────────────────────────────────────────────────────────────────────────

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _tripService = TripService();
  final _scrollController = ScrollController();

  List<TripModel> _trips = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  SearchArgs? get _args {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is SearchArgs ? args : null;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _trips.isEmpty && _errorMessage == null) {
      _load();
    }
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

  String _dateToApi(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _parseBudget(String? budgetStr, void Function(double? min, double? max) cb) {
    if (budgetStr == null) {
      cb(null, null);
      return;
    }
    if (budgetStr == 'Under Rs.500') { cb(null, 500); }
    else if (budgetStr == 'Rs.500 - Rs.1,000') { cb(500, 1000); }
    else if (budgetStr == 'Rs.1,000 - Rs.3,000') { cb(1000, 3000); }
    else if (budgetStr == 'Rs.3,000 - Rs.8,000') { cb(3000, 8000); }
    else if (budgetStr == 'Rs.8,000 - Rs.20,000') { cb(8000, 20000); }
    else if (budgetStr == 'Rs.20,000+') { cb(20000, null); }
    else { cb(null, null); }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final args = _args;
      String? startDate;
      String? endDate;
      if (args?.dateRange != null) {
        startDate = _dateToApi(args!.dateRange!.start);
        endDate = _dateToApi(args.dateRange!.end);
      }
      
      double? bMin;
      double? bMax;
      _parseBudget(args?.budget, (min, max) {
        bMin = min;
        bMax = max;
      });

      final result = await _tripService.getTrips(
        page: 1,
        destination: args?.destination.isNotEmpty == true ? args?.destination : null,
        startDate: startDate,
        endDate: endDate,
        budgetMin: bMin,
        budgetMax: bMax,
      );
      
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
      
      final args = _args;
      String? startDate;
      String? endDate;
      if (args?.dateRange != null) {
        startDate = _dateToApi(args!.dateRange!.start);
        endDate = _dateToApi(args.dateRange!.end);
      }
      
      double? bMin;
      double? bMax;
      _parseBudget(args?.budget, (min, max) {
        bMin = min;
        bMax = max;
      });

      final result = await _tripService.getTrips(
        page: nextPage,
        destination: args?.destination.isNotEmpty == true ? args?.destination : null,
        startDate: startDate,
        endDate: endDate,
        budgetMin: bMin,
        budgetMax: bMax,
      );

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

  void _onCardTap(TripModel trip) {
    Navigator.of(context).pushNamed(
      AppRoutes.tripDetail,
      arguments: trip.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final args = _args;
    final destination = args?.destination.isNotEmpty == true ? args!.destination : 'Discover';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _SrHeader(destination: destination, args: args),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _ErrorView(message: _errorMessage!, onRetry: _load)
                    : _trips.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _load,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(
                                AppConstants.screenPaddingH,
                                AppConstants.spacingMd,
                                AppConstants.screenPaddingH,
                                MediaQuery.paddingOf(context).bottom + AppConstants.spacingLg,
                              ),
                              itemCount: _trips.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == 0 && index == _trips.length) {
                                  // Handled by _trips.isEmpty above
                                  return const SizedBox();
                                }
                                
                                if (index == _trips.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }

                                if (index == 0) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                                        child: Text(
                                          '${_trips.length}${_hasMore ? '+' : ''} trips found',
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ),
                                      TripCard(
                                        data: TripCardData.fromTripModel(_trips[index]),
                                        onTap: () => _onCardTap(_trips[index]),
                                      ),
                                    ],
                                  );
                                }

                                return TripCard(
                                  data: TripCardData.fromTripModel(_trips[index]),
                                  onTap: () => _onCardTap(_trips[index]),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _SrHeader extends StatelessWidget {
  const _SrHeader({required this.destination, required this.args});
  final String destination;
  final SearchArgs? args;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final dateStr = args?.dateRange != null
        ? '${args!.dateRange!.start.day}/${args!.dateRange!.start.month} – ${args!.dateRange!.end.day}/${args!.dateRange!.end.month}'
        : 'Any dates';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back row
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 17),
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Text(
                'Search Results',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ]),

          const SizedBox(height: AppConstants.spacingMd),

          // Destination
          Row(children: [
            const Icon(Icons.location_on_rounded,
                color: AppColors.primaryLight, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                destination,
                style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3),
              ),
            ),
          ]),
          const SizedBox(height: 6),

          // Chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _InfoChip(icon: Icons.calendar_today_rounded, label: dateStr),
              if (args?.lookingFor != null) ...[
                const SizedBox(width: AppConstants.spacingSm),
                _InfoChip(
                    icon: Icons.people_outline_rounded,
                    label: args!.lookingFor!),
              ],
              if (args?.budget != null) ...[
                const SizedBox(width: AppConstants.spacingSm),
                _InfoChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: args!.budget!),
              ]
            ]),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.80)),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.88))),
      ]),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight, width: 2),
          ),
          child: const Icon(Icons.flight_takeoff_rounded,
              size: 40, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text('No trips found',
            style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight)),
        const SizedBox(height: 6),
        Text('Try adjusting your search filters',
            style: GoogleFonts.nunito(
                fontSize: 14, color: AppColors.textSecondaryLight)),
      ]),
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
