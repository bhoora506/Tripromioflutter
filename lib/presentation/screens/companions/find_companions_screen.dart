import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

/// Arguments passed from FindCompanionsScreen to SearchResultsScreen.
class SearchArgs {
  const SearchArgs({
    required this.destination,
    this.dateRange,
    this.budget,
    this.lookingFor,
  });
  final String destination;
  final DateTimeRange? dateRange;
  final String? budget;
  final String? lookingFor;
}

class FindCompanionsScreen extends StatefulWidget {
  const FindCompanionsScreen({super.key});

  @override
  State<FindCompanionsScreen> createState() => _FindCompanionsScreenState();
}

class _FindCompanionsScreenState extends State<FindCompanionsScreen> {
  final _destinationController = TextEditingController();
  DateTimeRange? _dateRange;
  TimeOfDay? _departureTime;
  String? _selectedBudget;
  String? _selectedLookingFor;

  static const _budgetOptions = [
    'Under Rs.500',
    'Rs.500 - Rs.1,000',
    'Rs.1,000 - Rs.3,000',
    'Rs.3,000 - Rs.8,000',
    'Rs.8,000 - Rs.20,000',
    'Rs.20,000+',
  ];

  static const _lookingForOptions = [
    'Solo traveller',
    'Couple',
    'Small group (3-5)',
    'Large group (6+)',
    'Family-friendly',
  ];

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
      lastDate: now.add(const Duration(days: 365)),
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _departureTime = picked);
  }

  void _showPicker({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
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
        selected: selected,
        onSelect: (val) {
          onSelect(val);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onFindCompanions() {
    final dest = _destinationController.text.trim();
    Navigator.of(context).pushNamed(
      AppRoutes.discover,
      arguments: SearchArgs(
        destination: dest.isEmpty ? 'Any destination' : dest,
        dateRange: _dateRange,
        budget: _selectedBudget,
        lookingFor: _selectedLookingFor,
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
      return '${s.day} - ${e.day} ${mo[s.month]}';
    }
    return '${s.day} ${mo[s.month]} - ${e.day} ${mo[e.month]}';
  }

  String _fmtTime() {
    if (_departureTime == null) return 'Select departure time';
    final h =
        _departureTime!.hourOfPeriod == 0 ? 12 : _departureTime!.hourOfPeriod;
    final m = _departureTime!.minute.toString().padLeft(2, '0');
    final p = _departureTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
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
                  ),

                  const SizedBox(height: AppConstants.spacingMd),
                  const _Label('Departure Time'),
                  const SizedBox(height: AppConstants.spacingXs),
                  _TapField(
                    icon: Icons.schedule_rounded,
                    value: _fmtTime(),
                    hasValue: _departureTime != null,
                    onTap: _pickTime,
                  ),

                  const SizedBox(height: AppConstants.spacingMd),
                  const _Label('Budget Range'),
                  const SizedBox(height: AppConstants.spacingXs),
                  _TapField(
                    icon: Icons.account_balance_wallet_outlined,
                    value: _selectedBudget ?? 'Select budget range',
                    hasValue: _selectedBudget != null,
                    onTap: () => _showPicker(
                      title: 'Select Budget Range',
                      options: _budgetOptions,
                      selected: _selectedBudget,
                      onSelect: (v) => setState(() => _selectedBudget = v),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),
                  const _Label('Looking For'),
                  const SizedBox(height: AppConstants.spacingXs),
                  _TapField(
                    icon: Icons.people_outline_rounded,
                    value: _selectedLookingFor ?? 'Who are you looking for?',
                    hasValue: _selectedLookingFor != null,
                    onTap: () => _showPicker(
                      title: 'Looking For',
                      options: _lookingForOptions,
                      selected: _selectedLookingFor,
                      onSelect: (v) => setState(() => _selectedLookingFor = v),
                    ),
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
  });

  final IconData icon;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

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
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

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
          ...options.map((opt) {
            final sel = opt == selected;
            return InkWell(
              onTap: () => onSelect(opt),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPaddingH, vertical: 13),
                child: Row(children: [
                  Expanded(
                    child: Text(opt,
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
