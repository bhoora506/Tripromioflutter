// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/interest_model.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/trip_service.dart';
import '../../../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreateTripScreen
// ─────────────────────────────────────────────────────────────────────────────

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _tripService = TripService();
  final _profileService = ProfileService();

  final _titleCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _startDate;
  DateTime? _endDate;
  TripType? _selectedTripType;
  int _maxMembers = 4;
  List<InterestModel> _allInterests = [];
  final Set<int> _selectedInterestIds = {};
  bool _loadingInterests = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _destinationCtrl.dispose();
    _descriptionCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    _tripService.dispose();
    _profileService.dispose();
    super.dispose();
  }

  Future<void> _loadInterests() async {
    try {
      final interests = await _profileService.getInterests();
      if (!mounted) return;
      setState(() {
        _allInterests = interests;
        _loadingInterests = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingInterests = false);
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
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
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final start = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? start,
      firstDate: start,
      lastDate: start.add(const Duration(days: 730)),
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
    if (picked != null && mounted) {
      setState(() => _endDate = picked);
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Select date';
    const mo = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${mo[d.month]} ${d.year}';
  }

  String _dateToApi(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showTripTypePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXl)),
      ),
      builder: (_) => _TripTypeSheet(
        selected: _selectedTripType,
        onSelect: (type) {
          setState(() => _selectedTripType = type);
          Navigator.pop(context);
        },
      ),
    );
  }

  String? _validateForm() {
    if (_titleCtrl.text.trim().length < 3) return 'Title must be at least 3 characters.';
    if (_destinationCtrl.text.trim().isEmpty) return 'Destination is required.';
    if (_startDate == null) return 'Start date is required.';
    if (_endDate == null) return 'End date is required.';
    if (_selectedTripType == null) return 'Trip type is required.';

    final minStr = _budgetMinCtrl.text.trim();
    final maxStr = _budgetMaxCtrl.text.trim();
    if (minStr.isNotEmpty) {
      final val = double.tryParse(minStr);
      if (val == null || val < 0) return 'Budget minimum must be a valid positive number.';
    }
    if (maxStr.isNotEmpty) {
      final val = double.tryParse(maxStr);
      if (val == null || val < 0) return 'Budget maximum must be a valid positive number.';
    }
    if (minStr.isNotEmpty && maxStr.isNotEmpty) {
      final min = double.tryParse(minStr) ?? 0;
      final max = double.tryParse(maxStr) ?? 0;
      if (max < min) return 'Budget maximum must be ≥ minimum.';
    }
    if (_selectedInterestIds.length > 10) return 'Maximum 10 interests allowed.';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final error = _validateForm();
    if (error != null) {
      _showSnack(error);
      return;
    }

    setState(() => _submitting = true);

    try {
      final trip = await _tripService.createTrip(
        title: _titleCtrl.text.trim(),
        destination: _destinationCtrl.text.trim(),
        startDate: _dateToApi(_startDate!),
        endDate: _dateToApi(_endDate!),
        tripType: _selectedTripType!,
        maxMembers: _maxMembers,
        budgetMin: _budgetMinCtrl.text.trim().isNotEmpty
            ? double.tryParse(_budgetMinCtrl.text.trim())
            : null,
        budgetMax: _budgetMaxCtrl.text.trim().isNotEmpty
            ? double.tryParse(_budgetMaxCtrl.text.trim())
            : null,
        description: _descriptionCtrl.text.trim().isNotEmpty
            ? _descriptionCtrl.text.trim()
            : null,
        interestIds:
            _selectedInterestIds.isNotEmpty ? _selectedInterestIds.toList() : null,
      );

      if (!mounted) return;
      _showSnack('Trip created successfully!', isSuccess: true);

      // Navigate to Trip Details with the created trip
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.tripDetail,
        arguments: trip.id,
      );
    } on ValidationException catch (e) {
      if (!mounted) return;
      final fieldErrors = e.errors?.values.expand((v) => v).join('\n');
      _showSnack(fieldErrors ?? e.message);
    } on NetworkException {
      if (!mounted) return;
      _showSnack('No internet connection. Please retry.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) return;
      _showSnack('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(AppConstants.screenPaddingH),
      ),
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
                  'Create Trip',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ── Form ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppConstants.screenPaddingH,
                AppConstants.spacingLg,
                AppConstants.screenPaddingH,
                botPad + AppConstants.spacingLg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    _FieldLabel('Trip Title *'),
                    const SizedBox(height: AppConstants.spacingXs),
                    _StyledTextField(
                      controller: _titleCtrl,
                      hint: 'e.g. Weekend in Goa',
                      maxLength: 200,
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Destination
                    _FieldLabel('Destination *'),
                    const SizedBox(height: AppConstants.spacingXs),
                    _StyledTextField(
                      controller: _destinationCtrl,
                      hint: 'e.g. Goa, India',
                      maxLength: 200,
                      icon: Icons.location_on_rounded,
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Dates
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Start Date *'),
                              const SizedBox(height: AppConstants.spacingXs),
                              _DateField(
                                value: _fmtDate(_startDate),
                                hasValue: _startDate != null,
                                onTap: _pickStartDate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('End Date *'),
                              const SizedBox(height: AppConstants.spacingXs),
                              _DateField(
                                value: _fmtDate(_endDate),
                                hasValue: _endDate != null,
                                onTap: _pickEndDate,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Budget
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Budget Min'),
                              const SizedBox(height: AppConstants.spacingXs),
                              _StyledTextField(
                                controller: _budgetMinCtrl,
                                hint: 'e.g. 5000',
                                keyboardType: TextInputType.number,
                                icon: Icons.currency_rupee_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Budget Max'),
                              const SizedBox(height: AppConstants.spacingXs),
                              _StyledTextField(
                                controller: _budgetMaxCtrl,
                                hint: 'e.g. 15000',
                                keyboardType: TextInputType.number,
                                icon: Icons.currency_rupee_rounded,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Trip Type
                    _FieldLabel('Trip Type *'),
                    const SizedBox(height: AppConstants.spacingXs),
                    GestureDetector(
                      onTap: _showTripTypePicker,
                      child: _DateField(
                        value: _selectedTripType != null
                            ? _tripTypeDisplayLabel(_selectedTripType!)
                            : 'Select trip type',
                        hasValue: _selectedTripType != null,
                        icon: Icons.hiking_rounded,
                        onTap: _showTripTypePicker,
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Max Members
                    _FieldLabel('Maximum Members * (including you)'),
                    const SizedBox(height: AppConstants.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMd,
                        vertical: AppConstants.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: AppConstants.spacingSm),
                          Expanded(
                            child: Slider(
                              value: _maxMembers.toDouble(),
                              min: 2,
                              max: 20,
                              divisions: 18,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.borderLight,
                              label: '$_maxMembers',
                              onChanged: (v) =>
                                  setState(() => _maxMembers = v.round()),
                            ),
                          ),
                          Container(
                            width: 36,
                            alignment: Alignment.center,
                            child: Text(
                              '$_maxMembers',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Description
                    _FieldLabel('Description'),
                    const SizedBox(height: AppConstants.spacingXs),
                    _StyledTextField(
                      controller: _descriptionCtrl,
                      hint: 'Tell others about your trip...',
                      maxLength: 5000,
                      maxLines: 4,
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Interests
                    _FieldLabel('Interests (max 10)'),
                    const SizedBox(height: AppConstants.spacingXs),
                    if (_loadingInterests)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: AppConstants.spacingSm,
                        runSpacing: AppConstants.spacingSm,
                        children: _allInterests.map((interest) {
                          final selected =
                              _selectedInterestIds.contains(interest.id);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selectedInterestIds.remove(interest.id);
                                } else if (_selectedInterestIds.length < 10) {
                                  _selectedInterestIds.add(interest.id);
                                } else {
                                  _showSnack('Maximum 10 interests allowed.');
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: AppConstants.animationFast,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.surfaceLight,
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusFull),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Text(
                                interest.name,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight:
                                      selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: AppConstants.spacingXl),

                    // Submit Button
                    GestureDetector(
                      onTap: _submitting ? null : _submit,
                      child: AnimatedContainer(
                        duration: AppConstants.animationFast,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: _submitting
                              ? null
                              : const LinearGradient(
                                  colors: AppColors.primaryGradient,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: _submitting ? AppColors.borderLight : null,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd),
                          boxShadow: _submitting
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Create Trip',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingMd),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _tripTypeDisplayLabel(TripType type) {
  switch (type) {
    case TripType.weekend:      return 'Weekend';
    case TripType.adventure:    return 'Adventure';
    case TripType.backpacking:  return 'Backpacking';
    case TripType.roadTrip:     return 'Road Trip';
    case TripType.nature:       return 'Nature';
    case TripType.photography:  return 'Photography';
    case TripType.cultural:     return 'Cultural';
    case TripType.beach:        return 'Beach';
    case TripType.mountains:    return 'Mountains';
    case TripType.other:        return 'Other';
  }
}

// ── Reusable form widgets ────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
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

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.icon,
  });

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? icon;

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(
                left: AppConstants.spacingMd,
                top: maxLines > 1 ? 14 : 0,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textHintLight,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: icon != null
                      ? AppConstants.spacingSm
                      : AppConstants.spacingMd,
                  vertical: maxLines > 1 ? 14 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.hasValue,
    required this.onTap,
    this.icon,
  });

  final String value;
  final bool hasValue;
  final VoidCallback onTap;
  final IconData? icon;

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
            color:
                hasValue ? AppColors.primary.withValues(alpha: 0.4) : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon ?? Icons.calendar_today_rounded,
              size: 18,
              color: hasValue ? AppColors.primary : AppColors.textSecondaryLight,
            ),
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
          ],
        ),
      ),
    );
  }
}

// ── Trip Type bottom sheet ────────────────────────────────────────────────────

class _TripTypeSheet extends StatelessWidget {
  const _TripTypeSheet({required this.selected, required this.onSelect});

  final TripType? selected;
  final ValueChanged<TripType> onSelect;

  static const _icons = <TripType, IconData>{
    TripType.weekend: Icons.weekend_rounded,
    TripType.adventure: Icons.terrain_rounded,
    TripType.backpacking: Icons.backpack_rounded,
    TripType.roadTrip: Icons.directions_car_rounded,
    TripType.nature: Icons.forest_rounded,
    TripType.photography: Icons.camera_alt_rounded,
    TripType.cultural: Icons.museum_rounded,
    TripType.beach: Icons.beach_access_rounded,
    TripType.mountains: Icons.landscape_rounded,
    TripType.other: Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppConstants.spacingMd, 0, AppConstants.spacingLg),
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
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenPaddingH),
            child: Text(
              'Select Trip Type',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          ...TripType.values.map((type) {
            final sel = type == selected;
            return InkWell(
              onTap: () => onSelect(type),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPaddingH, vertical: 13),
                child: Row(
                  children: [
                    Icon(
                      _icons[type] ?? Icons.trip_origin_rounded,
                      size: 20,
                      color: sel ? AppColors.primary : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Text(
                        _tripTypeDisplayLabel(type),
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? AppColors.primary : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    if (sel)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
