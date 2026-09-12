import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/trip_card.dart';

import '../../../data/models/trip_model.dart';
import '../../../data/services/trip_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home screen + navigation shell
// ─────────────────────────────────────────────────────────────────────────────

const _kTopDestinations = [
  _Destination(name: 'Manali', icon: Icons.ac_unit_rounded, seed: 0),
  _Destination(name: 'Goa', icon: Icons.beach_access_rounded, seed: 1),
  _Destination(name: 'Udaipur', icon: Icons.location_city_rounded, seed: 3),
  _Destination(name: 'Kashmir', icon: Icons.landscape_rounded, seed: 2),
  _Destination(name: 'Coorg', icon: Icons.forest_rounded, seed: 5),
  _Destination(name: 'Spiti', icon: Icons.terrain_rounded, seed: 4),
];

class _Destination {
  const _Destination({
    required this.name,
    required this.icon,
    required this.seed,
  });

  final String name;
  final IconData icon;
  final int seed;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Bottom-nav item definitions
  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Home', icon: Icons.home_rounded, activeIcon: Icons.home_rounded),
    _NavItem(label: 'Trips', icon: Icons.map_outlined, activeIcon: Icons.map_rounded),
    _NavItem(label: '', icon: Icons.add, activeIcon: Icons.add), // centre FAB
    _NavItem(label: 'Chats', icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
  ];

  void _onNavTap(int index) {
    if (index == 2) {
      // Create trip — navigate to placeholder until implemented
      Navigator.of(context).pushNamed(AppRoutes.createTrip);
      return;
    }

    // For tabs other than Home, push the placeholder route
    if (index != 0 && _selectedIndex != index) {
      switch (index) {
        case 1:
          Navigator.of(context).pushNamed(AppRoutes.trips);
        case 3:
          Navigator.of(context).pushNamed(AppRoutes.conversations);
        case 4:
          Navigator.of(context).pushNamed(AppRoutes.profile);
      }
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Light status bar to match the home screen's light header.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      // No AppBar — using custom header in scroll body
      body: _selectedIndex == 0
          ? const _HomeBody()
          : const SizedBox.shrink(), // other tabs push their own routes
      bottomNavigationBar: _BottomNavBar(
        items: _navItems,
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isCenter = i == 2;
            final isActive = i == selectedIndex;

            if (isCenter) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.40),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              );
            }

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: AppConstants.animationFast,
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        key: ValueKey(isActive),
                        size: 24,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: AppConstants.animationFast,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                      ),
                      child: Text(item.label),
                    ),
                    // Active dot indicator
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: AppConstants.animationFast,
                      width: isActive ? 16 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusFull),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home body — scrollable content (real API)
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final _tripService = TripService();
  List<TripModel> _trips = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void dispose() {
    _tripService.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // By default, getTrips() returns published trips
      final result = await _tripService.getTrips(perPage: 5);
      if (!mounted) return;
      setState(() {
        _trips = result.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load popular trips.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadTrips,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Safe-area top spacing + header
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient background
                const _HomeHeader(),
                const SizedBox(height: AppConstants.spacingMd),
                // Search bar
                const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.screenPaddingH),
                  child: _SearchBar(),
                ),
                const SizedBox(height: AppConstants.spacingXl),
              ],
            ),
          ),

          // Popular Trips section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingH),
              child: _SectionHeader(
                title: 'Popular Trips Near You',
                onViewAll: () => Navigator.of(context).pushNamed(AppRoutes.discover),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spacingMd)),

          // Trip cards
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.nunito(color: AppColors.textSecondaryLight),
                  ),
                ),
              ),
            )
          else if (_trips.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No popular trips found.',
                    style: GoogleFonts.nunito(color: AppColors.textSecondaryLight),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingH),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final trip = _trips[i];
                    return TripCard(
                      data: TripCardData.fromTripModel(trip),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.tripDetail,
                          arguments: trip.id,
                        );
                      },
                    );
                  },
                  childCount: _trips.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spacingXl)),

          // Top Destinations section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingH),
              child: _SectionHeader(
                title: 'Top Destinations',
                onViewAll: () {},
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spacingMd)),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(
                    left: AppConstants.screenPaddingH,
                    right: AppConstants.spacingSm),
                physics: const BouncingScrollPhysics(),
                itemCount: _kTopDestinations.length,
                itemBuilder: (_, i) =>
                    _DestinationChip(dest: _kTopDestinations[i]),
              ),
            ),
          ),

          // Bottom breathing room above nav bar
          const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spacingXxl)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

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
          colors: [
            Color(0xFF0A1628),
            Color(0xFF0F3460),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.radiusXl),
          bottomRight: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: greeting + avatar + notification
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey, Arjun! 👋',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Where are you exploring next?',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              // Notification button
              _HeaderIconBtn(
                icon: Icons.notifications_outlined,
                badgeCount: 3,
                onTap: () {},
              ),
              const SizedBox(width: AppConstants.spacingSm),
              // Avatar
              _UserAvatar(),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Quick stats row
          Row(
            children: const [
              _StatBadge(value: '12', label: 'Trips'),
              SizedBox(width: AppConstants.spacingMd),
              _StatBadge(value: '28', label: 'Reviews'),
              SizedBox(width: AppConstants.spacingMd),
              _StatBadge(value: '4.8 ★', label: 'Rating'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6CF8), Color(0xFF8B9CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 2,
        ),
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.findCompanions);
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppConstants.spacingMd),
            const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(
                'Where do you want to go?',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHintLight,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXs, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              child: Text(
                'Search',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
              letterSpacing: -0.3,
            ),
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View all',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Destination chip
// ─────────────────────────────────────────────────────────────────────────────

class _DestinationChip extends StatelessWidget {
  const _DestinationChip({required this.dest});

  final _Destination dest;

  static const List<List<Color>> _chipGradients = [
    [Color(0xFF5B6CF8), Color(0xFF8B9CF8)],
    [Color(0xFF3DAF8A), Color(0xFF70CDB3)],
    [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    [Color(0xFF004D40), Color(0xFF00897B)],
    [Color(0xFF1B5E20), Color(0xFF388E3C)],
    [Color(0xFFFF7B54), Color(0xFFFFAA85)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _chipGradients[dest.seed % _chipGradients.length];

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: AppConstants.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle in background
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(dest.icon, color: Colors.white, size: 20),
                ),
                Text(
                  dest.name,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

