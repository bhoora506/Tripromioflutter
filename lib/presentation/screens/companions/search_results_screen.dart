import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import 'find_companions_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data model
// ─────────────────────────────────────────────────────────────────────────────

class TravellerData {
  const TravellerData({
    required this.id,
    required this.name,
    required this.destination,
    required this.dateRange,
    required this.lookingFor,
    required this.rating,
    required this.tripsCount,
    required this.avatarSeed,
    required this.bio,
  });

  final String id;
  final String name;
  final String destination;
  final String dateRange;
  final String lookingFor;
  final double rating;
  final int tripsCount;
  final int avatarSeed;
  final String bio;
}

const _kMockTravellers = [
  TravellerData(
    id: 't-01',
    name: 'Priya Sharma',
    destination: 'Manali, Himachal Pradesh',
    dateRange: '15 Sep – 22 Sep',
    lookingFor: 'Solo traveller',
    rating: 4.8,
    tripsCount: 14,
    avatarSeed: 0,
    bio: 'Adventure lover and trek enthusiast. Looking for a co-traveller to explore the Rohtang Pass.',
  ),
  TravellerData(
    id: 't-02',
    name: 'Arjun Mehta',
    destination: 'Manali, Himachal Pradesh',
    dateRange: '18 Sep – 24 Sep',
    lookingFor: 'Small group (3-5)',
    rating: 4.5,
    tripsCount: 8,
    avatarSeed: 1,
    bio: 'Backpacker by soul. Planning a 6-day trip covering Old Manali and Solang Valley.',
  ),
  TravellerData(
    id: 't-03',
    name: 'Kavya Nair',
    destination: 'Manali, Himachal Pradesh',
    dateRange: '20 Sep – 27 Sep',
    lookingFor: 'Couple',
    rating: 4.9,
    tripsCount: 21,
    avatarSeed: 2,
    bio: 'Experienced traveller looking for like-minded companions for a week in the mountains.',
  ),
  TravellerData(
    id: 't-04',
    name: 'Rohan Verma',
    destination: 'Manali, Himachal Pradesh',
    dateRange: '14 Sep – 21 Sep',
    lookingFor: 'Large group (6+)',
    rating: 4.3,
    tripsCount: 5,
    avatarSeed: 3,
    bio: 'First time in Manali! Planning a budget trip and would love company for local sightseeing.',
  ),
  TravellerData(
    id: 't-05',
    name: 'Ananya Gupta',
    destination: 'Manali, Himachal Pradesh',
    dateRange: '17 Sep – 23 Sep',
    lookingFor: 'Solo traveller',
    rating: 4.7,
    tripsCount: 12,
    avatarSeed: 4,
    bio: 'Solo female traveller with 12 trips under the belt. Nature photographer looking for trekking partner.',
  ),
];

const _kAvatarColors = [
  [Color(0xFF5B6CF8), Color(0xFF9B7CF8)],
  [Color(0xFFF85B6C), Color(0xFFF87C5B)],
  [Color(0xFF5BF8A0), Color(0xFF5BDDF8)],
  [Color(0xFFF8D45B), Color(0xFFF89F5B)],
  [Color(0xFF5BB8F8), Color(0xFF5B6CF8)],
];

// ─────────────────────────────────────────────────────────────────────────────
// SearchResultsScreen
// ─────────────────────────────────────────────────────────────────────────────

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _loadedMore = false;

  SearchArgs? get _args {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is SearchArgs ? args : null;
  }

  void _onConnect(TravellerData traveller) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Connection request sent to ${traveller.name}!',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(AppConstants.screenPaddingH),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onCardTap(TravellerData traveller) {
    Navigator.of(context).pushNamed(
      AppRoutes.tripDetail,
      arguments: traveller,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final args = _args;
    final destination = args?.destination ?? 'Companions';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _SrHeader(destination: destination, args: args),
          Expanded(
            child: _kMockTravellers.isEmpty
                ? const _EmptyState()
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppConstants.screenPaddingH,
                      AppConstants.spacingMd,
                      AppConstants.screenPaddingH,
                      MediaQuery.paddingOf(context).bottom + AppConstants.spacingLg,
                    ),
                    children: [
                      // Results count
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                        child: Row(
                          children: [
                            Text(
                              '${_kMockTravellers.length} travel companions found',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Cards
                      ..._kMockTravellers.map((t) => _TravellerCard(
                            traveller: t,
                            onConnect: () => _onConnect(t),
                            onTap: () => _onCardTap(t),
                          )),

                      // Load more
                      const SizedBox(height: AppConstants.spacingMd),
                      if (!_loadedMore)
                        _LoadMoreBtn(
                          onTap: () => setState(() => _loadedMore = true),
                        )
                      else
                        Center(
                          child: Text(
                            "You've seen all results",
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
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
          Row(children: [
            _InfoChip(icon: Icons.calendar_today_rounded, label: dateStr),
            const SizedBox(width: AppConstants.spacingSm),
            _InfoChip(
                icon: Icons.people_outline_rounded,
                label: args?.lookingFor ?? 'Any'),
          ]),
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

// ── Traveller Card ────────────────────────────────────────────────────────────

class _TravellerCard extends StatelessWidget {
  const _TravellerCard({
    required this.traveller,
    required this.onConnect,
    required this.onTap,
  });

  final TravellerData traveller;
  final VoidCallback onConnect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final idx = traveller.avatarSeed % _kAvatarColors.length;
    final colors = _kAvatarColors[idx];
    final initials = traveller.name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row: avatar + name + rating
          Row(children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),

            // Name + destination
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(traveller.name,
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.location_on_rounded,
                      size: 13, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      traveller.destination,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight),
                    ),
                  ),
                ]),
              ]),
            ),

            // Rating
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                const SizedBox(width: 3),
                Text('${traveller.rating}',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight)),
              ]),
              const SizedBox(height: 2),
              Text('${traveller.tripsCount} trips',
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500)),
            ]),
          ]),

          const SizedBox(height: AppConstants.spacingSm),

          // Bio
          Text(
            traveller.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w400,
                height: 1.45),
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // Tags + date row
          Row(children: [
            _MiniChip(
                icon: Icons.calendar_today_rounded,
                label: traveller.dateRange),
            const SizedBox(width: AppConstants.spacingXs),
            _MiniChip(
                icon: Icons.people_outline_rounded,
                label: traveller.lookingFor),
          ]),

          const SizedBox(height: AppConstants.spacingMd),

          // Connect button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
                textStyle: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: const Text('Connect'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(children: [
        Icon(icon, size: 11, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight)),
      ]),
    );
  }
}

// ── Load More ─────────────────────────────────────────────────────────────────

class _LoadMoreBtn extends StatelessWidget {
  const _LoadMoreBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: AppConstants.spacingXs),
          Text('Load More',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ]),
      ),
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
          child: const Icon(Icons.people_outline_rounded,
              size: 40, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text('No companions found',
            style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight)),
        const SizedBox(height: 6),
        Text('Try adjusting your filters',
            style: GoogleFonts.nunito(
                fontSize: 14, color: AppColors.textSecondaryLight)),
      ]),
    );
  }
}
