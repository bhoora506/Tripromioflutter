// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/services/trip_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EditTripScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Edits an existing trip. Receives a [TripModel] as route arguments.
///
/// Status-based editability:
/// - **Draft / Published**: all fields editable
/// - **Ongoing**: only title + description
/// - **Completed / Cancelled**: edit not allowed (route guard in [build])
class EditTripScreen extends StatefulWidget {
  const EditTripScreen({super.key});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _tripService = TripService();

  final _titleCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();

  TripModel? _trip;
  DateTime? _startDate;
  DateTime? _endDate;
  TripType? _selectedTripType;
  int _maxMembers = 4;
  bool _submitting = false;
  bool _initialized = false;

  /// Whether all form fields are editable (draft / published).
  bool get _fullEdit {
    final s = _trip?.status;
    return s == TripStatus.draft || s == TripStatus.published;
  }

  /// Whether the trip is in a non-editable terminal state.
  bool get _notEditable {
    final s = _trip?.status;
    return s == TripStatus.completed || s == TripStatus.cancelled;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is TripModel) {
        _trip = args;
        _populateFields(args);
        _initialized = true;
      }
    }
  }

  void _populateFields(TripModel trip) {
    _titleCtrl.text = trip.title;
    _destinationCtrl.text = trip.destination;
    _descriptionCtrl.text = trip.description ?? '';
    _budgetMinCtrl.text =
        trip.budgetMin != null ? trip.budgetMin!.toStringAsFixed(0) : '';
    _budgetMaxCtrl.text =
        trip.budgetMax != null ? trip.budgetMax!.toStringAsFixed(0) : '';
    _selectedTripType = trip.tripType;
    _maxMembers = trip.maxMembers;

    if (trip.startDate != null) {
      _startDate = DateTime.tryParse(trip.startDate!);
    }
    if (trip.endDate != null) {
      _endDate = DateTime.tryParse(trip.endDate!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _destinationCtrl.dispose();
    _descriptionCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    _tripService.dispose();
    super.dispose();
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

  Future<void> _pickStartDate() async {
    if (!_fullEdit) return;
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
    if (!_fullEdit) return;
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

  void _showTripTypePicker() {
    if (!_fullEdit) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXl)),
      ),
      builder: (_) => _TripTypeEditSheet(
        selected: _selectedTripType,
        onSelect: (type) {
          setState(() => _selectedTripType = type);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting || _trip == null) return;

    // Basic validation
    if (_titleCtrl.text.trim().length < 3) {
      _showSnack('Title must be at least 3 characters.');
      return;
    }
    if (_fullEdit && _destinationCtrl.text.trim().isEmpty) {
      _showSnack('Destination is required.');
      return;
    }

    setState(() => _submitting = true);

    try {
      // Build named parameters — only send changed values
      final newTitle =
          _titleCtrl.text.trim() != _trip!.title ? _titleCtrl.text.trim() : null;
      final newDesc = _descriptionCtrl.text.trim() != (_trip!.description ?? '')
          ? _descriptionCtrl.text.trim()
          : null;

      String? newDest;
      String? newStartDate;
      String? newEndDate;
      TripType? newTripType;
      int? newMaxMembers;
      double? newBudgetMin;
      double? newBudgetMax;

      if (_fullEdit) {
        newDest = _destinationCtrl.text.trim() != _trip!.destination
            ? _destinationCtrl.text.trim()
            : null;
        if (_startDate != null) {
          final apiDate = _dateToApi(_startDate!);
          if (apiDate != _trip!.startDate) newStartDate = apiDate;
        }
        if (_endDate != null) {
          final apiDate = _dateToApi(_endDate!);
          if (apiDate != _trip!.endDate) newEndDate = apiDate;
        }
        if (_selectedTripType != null && _selectedTripType != _trip!.tripType) {
          newTripType = _selectedTripType;
        }
        if (_maxMembers != _trip!.maxMembers) newMaxMembers = _maxMembers;

        final minStr = _budgetMinCtrl.text.trim();
        if (minStr.isNotEmpty) {
          final val = double.tryParse(minStr);
          if (val != null && val != _trip!.budgetMin) newBudgetMin = val;
        }
        final maxStr = _budgetMaxCtrl.text.trim();
        if (maxStr.isNotEmpty) {
          final val = double.tryParse(maxStr);
          if (val != null && val != _trip!.budgetMax) newBudgetMax = val;
        }
      }

      // Check if anything changed
      if (newTitle == null &&
          newDesc == null &&
          newDest == null &&
          newStartDate == null &&
          newEndDate == null &&
          newTripType == null &&
          newMaxMembers == null &&
          newBudgetMin == null &&
          newBudgetMax == null) {
        _showSnack('No changes to save.');
        if (mounted) setState(() => _submitting = false);
        return;
      }

      final updated = await _tripService.updateTrip(
        _trip!.id,
        title: newTitle,
        destination: newDest,
        startDate: newStartDate,
        endDate: newEndDate,
        tripType: newTripType,
        maxMembers: newMaxMembers,
        description: newDesc,
        budgetMin: newBudgetMin,
        budgetMax: newBudgetMax,
      );
      if (!mounted) return;
      _showSnack('Trip updated!', isSuccess: true);

      // Pop back and return the updated trip
      Navigator.of(context).pop(updated);
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

    // Route guard: no TripModel passed or terminal status
    if (_trip == null || _notEditable) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Edit Trip')),
        body: Center(
          child: Text(
            _trip == null
                ? 'No trip data provided.'
                : 'This trip cannot be edited (${_trip!.status.name}).',
            style: GoogleFonts.nunito(
                fontSize: 15, color: AppColors.textSecondaryLight),
          ),
        ),
      );
    }

    final topPad = MediaQuery.paddingOf(context).top;
    final botPad = MediaQuery.paddingOf(context).bottom;
    final isOngoing = _trip!.status == TripStatus.ongoing;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 17),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Text(
                      'Edit Trip',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (isOngoing) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.20),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusFull),
                    ),
                    child: Text(
                      'Ongoing — only Title & Description can be edited',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  _EditLabel('Trip Title *'),
                  const SizedBox(height: AppConstants.spacingXs),
                  _EditTextField(controller: _titleCtrl, hint: 'Trip title'),

                  if (_fullEdit) ...[
                    const SizedBox(height: AppConstants.spacingMd),

                    // Destination
                    _EditLabel('Destination *'),
                    const SizedBox(height: AppConstants.spacingXs),
                    _EditTextField(
                      controller: _destinationCtrl,
                      hint: 'Destination',
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
                              _EditLabel('Start Date'),
                              const SizedBox(height: AppConstants.spacingXs),
                              _EditDateField(
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
                              _EditLabel('End Date'),
                              const SizedBox(height: AppConstants.spacingXs),
                              _EditDateField(
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
                              _EditLabel('Budget Min'),
                              const SizedBox(height: AppConstants.spacingXs),
                              _EditTextField(
                                controller: _budgetMinCtrl,
                                hint: 'Min',
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
                              _EditLabel('Budget Max'),
                              const SizedBox(height: AppConstants.spacingXs),
                              _EditTextField(
                                controller: _budgetMaxCtrl,
                                hint: 'Max',
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
                    _EditLabel('Trip Type'),
                    const SizedBox(height: AppConstants.spacingXs),
                    _EditDateField(
                      value: _selectedTripType != null
                          ? _editTripTypeLabel(_selectedTripType!)
                          : 'Select type',
                      hasValue: _selectedTripType != null,
                      icon: Icons.hiking_rounded,
                      onTap: _showTripTypePicker,
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // Max Members
                    _EditLabel('Maximum Members'),
                    const SizedBox(height: AppConstants.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMd,
                        vertical: AppConstants.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMd),
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
                  ],

                  const SizedBox(height: AppConstants.spacingMd),

                  // Description (always editable for ongoing)
                  _EditLabel('Description'),
                  const SizedBox(height: AppConstants.spacingXs),
                  _EditTextField(
                    controller: _descriptionCtrl,
                    hint: 'Describe your trip...',
                    maxLines: 4,
                  ),

                  const SizedBox(height: AppConstants.spacingXl),

                  // Submit
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
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
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
                                'Save Changes',
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
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _editTripTypeLabel(TripType type) {
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

// ── Reusable form atoms ──────────────────────────────────────────────────────

class _EditLabel extends StatelessWidget {
  const _EditLabel(this.text);
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

class _EditTextField extends StatelessWidget {
  const _EditTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.icon,
  });

  final TextEditingController controller;
  final String hint;
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
          if (icon != null)
            Padding(
              padding: EdgeInsets.only(
                left: AppConstants.spacingMd,
                top: maxLines > 1 ? 14 : 0,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    GoogleFonts.nunito(fontSize: 14, color: AppColors.textHintLight),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: icon != null
                      ? AppConstants.spacingSm
                      : AppConstants.spacingMd,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditDateField extends StatelessWidget {
  const _EditDateField({
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
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.borderLight,
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
                  color:
                      hasValue ? AppColors.textPrimaryLight : AppColors.textHintLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trip Type bottom sheet for Edit ──────────────────────────────────────────

class _TripTypeEditSheet extends StatelessWidget {
  const _TripTypeEditSheet({required this.selected, required this.onSelect});
  final TripType? selected;
  final ValueChanged<TripType> onSelect;

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
                    Expanded(
                      child: Text(
                        _editTripTypeLabel(type),
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color:
                              sel ? AppColors.primary : AppColors.textPrimaryLight,
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
