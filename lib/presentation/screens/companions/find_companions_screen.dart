import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

/// Arguments passed from [FindCompanionsScreen] to [CompanionDiscoveryScreen].
///
/// Only fields supported by GET /api/companions (CompanionDiscoveryRequest).
class CompanionSearchArgs {
  const CompanionSearchArgs({
    this.destination,
    this.dateRange,
    this.travelStyle,
    this.sort,
  });

  final String? destination;
  final DateTimeRange? dateRange;
  final String? travelStyle;
  final String? sort;
}

/// Travel style options supported by the backend TravelStyle enum.
const List<Map<String, String>> kTravelStyleOptions = [
  {'value': 'adventure', 'label': '🏔️ Adventure'},
  {'value': 'backpacking', 'label': '🎒 Backpacking'},
  {'value': 'budget', 'label': '💰 Budget'},
  {'value': 'luxury', 'label': '✨ Luxury'},
  {'value': 'relaxed', 'label': '🌴 Relaxed'},
  {'value': 'road_trip', 'label': '🚗 Road Trip'},
  {'value': 'nature', 'label': '🌿 Nature'},
  {'value': 'cultural', 'label': '🏛️ Cultural'},
];

/// Sort options supported by the backend CompanionDiscoveryRequest.
const List<Map<String, String>> kSortOptions = [
  {'value': 'profile_completion', 'label': 'Best Profiles'},
  {'value': 'newest', 'label': 'Newest'},
];

class FindCompanionsScreen extends StatefulWidget {
  const FindCompanionsScreen({super.key});

  @override
  State<FindCompanionsScreen> createState() => _FindCompanionsScreenState();
}

class _FindCompanionsScreenState extends State<FindCompanionsScreen> {
  final _destinationController = TextEditingController();
  DateTimeRange? _dateRange;
  String? _selectedTravelStyle;
  String? _selectedSort;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDateRange: _dateRange ??
          DateTimeRange(start: now, end: now.add(const Duration(days: 3))),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _dateRange = picked);
  }

  void _showStringPicker({
    required String title,
    required List<Map<String, String>> options,
    required String? selectedValue,
    required ValueChanged<String?> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXl)),
      ),
      builder: (_) => _OptionsSheet(
        title: title,
        options: options,
        selectedValue: selectedValue,
        onSelect: (val) {
          onSelect(val);
          Navigator.pop(context);
        },
        allowClear: true,
      ),
    );
  }

  void _onFindCompanions() {
    final dest = _destinationController.text.trim();
    Navigator.of(context).pushNamed(
      AppRoutes.discover,
      arguments: CompanionSearchArgs(
        destination: dest.isEmpty ? null : dest,
        dateRange: _dateRange,
        travelStyle: _selectedTravelStyle,
        sort: _selectedSort,
      ),
    );
  }

  String _fmtDates() {
    if (_dateRange == null) return 'Select travel dates';
    final s = _dateRange!.start;
    final e = _dateRange!.end;
    const mo = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (s.month == e.month && s.year == e.year) {
      return '${s.day} – ${e.day} ${mo[s.month]}';
    }
    return '${s.day} ${mo[s.month]} – ${e.day} ${mo[e.month]}';
  }

  String _styleLabel(String? value) {
    if (value == null) return 'Any travel style';
    return kTravelStyleOptions
            .firstWhere((o) => o['value'] == value,
                orElse: () => {'label': value})['label'] ??
        value;
  }

  String _sortLabel(String? value) {
    if (value == null) return 'Best Profiles (default)';
    return kSortOptions
            .firstWhere((o) => o['value'] == value,
                orElse: () => {'label': value})['label'] ??
        value;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    final topPad = MediaQuery.paddingOf(context).top;
    final botPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _FcHeader(topPad: topPad),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppConstants.screenPaddingH,
                AppConstants.spacingLg,
                AppConstants.screenPaddingH,
                botPad + AppConstants.spacingLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Label('Destination'),
                  const SizedBox(height: AppConstants.spacingXs),
                  _DestField(controller: _destinationController),

                  const SizedBox(height: AppConstants.spacingMd),
                  const _Label('Travel Dates'),
                  const SizedBox(height: AppConstants.spacingXs),
                  _TapField(
                    icon: Icons.calendar_today_rounded,
                    value: _fmtDates(),
                    hasValue: _dateRange != null,
                    onTap: _pickDateRange,
                    onClear: _dateRange != null
                        ? () => setState(() => _dateRange = null)
                        : null,
                  ),

                  const SizedBox(height: AppConstants.spacingMd),
                  const _Label('Travel Style'),
                  const SizedBox(height: AppConstants.spacingXs),
                  _TapField(
                    icon: Icons.backpack_rounded,
                    value: _styleLabel(_selectedTravelStyle),
                    hasValue: _selectedTravelStyle != null,
                    onTap: () => _showStringPicker(
                      title: 'Travel Style',
                      options: kTravelStyleOptions,
                      selectedValue: _selectedTravelStyle,
                      onSelect: (v) =>
                          setState(() => _selectedTravelStyle = v),
                    ),
                    onClear: _selectedTravelStyle != null
                        ? () => setState(() => _selectedTravelStyle = null)
                        : null,
                  ),

                  const SizedBox(height: AppConstants.spacingMd),
                  const _Label('Sort By'),
                  const SizedBox(height: AppConstants.spacingXs),
                  _TapField(
                    icon: Icons.sort_rounded,
                    value: _sortLabel(_selectedSort),
                    hasValue: _selectedSort != null,
                    onTap: () => _showStringPicker(
                      title: 'Sort By',
                      options: kSortOptions,
                      selectedValue: _selectedSort,
                      onSelect: (v) => setState(() => _selectedSort = v),
                    ),
                    onClear: _selectedSort != null
                        ? () => setState(() => _selectedSort = null)
                        : null,
                  ),

                  const SizedBox(height: AppConstants.spacingXl),
                  _FindBtn(onTap: _onFindCompanions),
                  const SizedBox(height: AppConstants.spacingMd),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _FcHeader extends StatelessWidget {
  const _FcHeader({required this.topPad});
  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.screenPaddingH,
        topPad + AppConstants.spacingMd,
        AppConstants.screenPaddingH,
        AppConstants.spacingXl,
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
          Row(children: [
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
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: 'Trip',
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight),
                ),
                TextSpan(
                  text: 'romio',
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Find Travel Partners',
              style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4)),
          const SizedBox(height: 4),
          Text(
            "Tell us your plan and we'll find the right companions",
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.68)),
          ),
        ],
      ),
    );
  }
}

// ── Form atoms ────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.3,
        ),
      );
}

class _DestField extends StatelessWidget {
  const _DestField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        const SizedBox(width: AppConstants.spacingMd),
        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: TextField(
            controller: controller,
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight),
            decoration: InputDecoration(
              hintText: 'e.g. Manali, Goa, Spiti Valley',
              hintStyle:
                  GoogleFonts.nunito(fontSize: 14, color: AppColors.textHintLight),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.icon,
    required this.value,
    required this.hasValue,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
              color: hasValue
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Icon(icon,
              size: 20,
              color: hasValue ? AppColors.primary : AppColors.textSecondaryLight),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                color: hasValue
                    ? AppColors.textPrimaryLight
                    : AppColors.textHintLight,
              ),
            ),
          ),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textSecondaryLight, size: 18),
            )
          else
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondaryLight, size: 20),
        ]),
      ),
    );
  }
}

class _FindBtn extends StatelessWidget {
  const _FindBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.search_rounded, color: Colors.white, size: 20),
          const SizedBox(width: AppConstants.spacingSm),
          Text('Find Companions',
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2)),
        ]),
      ),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
    this.allowClear = false,
  });

  final String title;
  final List<Map<String, String>> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelect;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          0, AppConstants.spacingMd, 0, AppConstants.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusFull)),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenPaddingH),
            child: Text(title,
                style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight)),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          if (allowClear && selectedValue != null) ...[
            InkWell(
              onTap: () => onSelect(null),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPaddingH, vertical: 13),
                child: Row(children: [
                  Expanded(
                    child: Text('Clear selection',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        )),
                  ),
                  const Icon(Icons.clear_rounded,
                      color: AppColors.textSecondaryLight, size: 18),
                ]),
              ),
            ),
            const Divider(height: 1),
          ],
          ...options.map((opt) {
            final val = opt['value']!;
            final label = opt['label']!;
            final sel = val == selectedValue;
            return InkWell(
              onTap: () => onSelect(val),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPaddingH, vertical: 13),
                child: Row(children: [
                  Expanded(
                    child: Text(label,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color:
                              sel ? AppColors.primary : AppColors.textPrimaryLight,
                        )),
                  ),
                  if (sel)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}
