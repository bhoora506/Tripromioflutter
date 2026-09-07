import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/profile_service.dart';

/// Edit-profile screen — sends PUT /api/profile with changed fields.
///
/// Receives the current [UserModel] as a route argument so the form can be
/// pre-populated without an extra network request.
///
/// On successful save it pops with the updated [UserModel] so that
/// [ProfileScreen] can refresh its display without reloading.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProfileService();

  // Controllers
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();

  // Languages state
  final List<String> _languages = [];
  final _langCtrl = TextEditingController();

  // Travel style
  String? _travelStyle;

  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;

  static const List<Map<String, String>> _travelStyles = [
    {'value': 'adventure', 'label': '🏔️ Adventure'},
    {'value': 'backpacking', 'label': '🎒 Backpacking'},
    {'value': 'budget', 'label': '💰 Budget'},
    {'value': 'luxury', 'label': '✨ Luxury'},
    {'value': 'relaxed', 'label': '🌴 Relaxed'},
    {'value': 'road_trip', 'label': '🚗 Road Trip'},
    {'value': 'nature', 'label': '🌿 Nature'},
    {'value': 'cultural', 'label': '🏛️ Cultural'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prefill();
  }

  void _prefill() {
    final user = ModalRoute.of(context)?.settings.arguments as UserModel?;
    if (user == null) return;

    final p = user.profile;
    if (p == null) return;

    _bioCtrl.text = p.bio ?? '';
    _cityCtrl.text = p.city ?? '';
    _countryCtrl.text = p.country ?? '';
    _languages
      ..clear()
      ..addAll(p.languages);
    _travelStyle = p.travelStyle;
    _budgetMinCtrl.text =
        p.preferredBudgetMin != null ? p.preferredBudgetMin!.toStringAsFixed(0) : '';
    _budgetMaxCtrl.text =
        p.preferredBudgetMax != null ? p.preferredBudgetMax!.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    _langCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  // ── Language management ───────────────────────────────────────────────────

  void _addLanguage() {
    final lang = _langCtrl.text.trim();
    if (lang.isEmpty) return;
    if (_languages.length >= 10) return;
    if (_languages.contains(lang)) {
      _langCtrl.clear();
      return;
    }
    setState(() {
      _languages.add(lang);
      _langCtrl.clear();
    });
  }

  void _removeLanguage(String lang) {
    setState(() => _languages.remove(lang));
  }

  // ── Travel style picker ───────────────────────────────────────────────────

  Future<void> _pickTravelStyle() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select Travel Style',
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const Divider(height: 1),
              ..._travelStyles.map((s) {
                final selected = s['value'] == _travelStyle;
                return ListTile(
                  title: Text(
                    s['label']!,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(s['value']),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ));
      },
    );
    if (picked != null && mounted) {
      setState(() => _travelStyle = picked);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    // Budget cross-validation
    final minRaw = double.tryParse(_budgetMinCtrl.text.trim());
    final maxRaw = double.tryParse(_budgetMaxCtrl.text.trim());
    if (minRaw != null && maxRaw != null && maxRaw < minRaw) {
      setState(() => _errorMessage =
          'Maximum budget must be greater than or equal to minimum budget.');
      return;
    }

    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    try {
      final updated = await _service.updateProfile(
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        country:
            _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
        languages: _languages.isEmpty ? null : List.from(_languages),
        travelStyle: _travelStyle,
        preferredBudgetMin: minRaw,
        preferredBudgetMax: maxRaw,
      );
      if (!mounted) return;
      // Pop with updated model so ProfileScreen refreshes immediately
      Navigator.of(context).pop(updated);
    } on ValidationException catch (e) {
      final fields = e.errors ?? {};
      final msgs = fields.values.expand((v) => v).join('\n');
      setState(() => _errorMessage = msgs.isNotEmpty ? msgs : e.message);
    } on UnauthorizedException {
      setState(
          () => _errorMessage = 'Session expired. Please log in again.');
    } on NetworkException {
      setState(() =>
          _errorMessage = 'No internet connection. Please retry.');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textPrimaryLight,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Error / success
            if (_errorMessage != null) ...[
              _Banner(message: _errorMessage!, isError: true),
              const SizedBox(height: 12),
            ],
            if (_successMessage != null) ...[
              _Banner(message: _successMessage!, isError: false),
              const SizedBox(height: 12),
            ],

            // ── Bio ─────────────────────────────────────────────────────────
            _FieldLabel('Bio'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 4,
              maxLength: 1000,
              enabled: !_loading,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Tell companions a bit about yourself…',
                counterText: '',
              ),
              validator: (v) {
                if (v != null && v.length > 1000) {
                  return 'Bio must be at most 1000 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── City + Country row ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('City'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cityCtrl,
                        textInputAction: TextInputAction.next,
                        enabled: !_loading,
                        style: GoogleFonts.nunito(fontSize: 14),
                        decoration:
                            const InputDecoration(hintText: 'e.g. Jaipur'),
                        validator: (v) {
                          if (v != null && v.length > 100) {
                            return 'Max 100 chars.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Country'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _countryCtrl,
                        textInputAction: TextInputAction.next,
                        enabled: !_loading,
                        style: GoogleFonts.nunito(fontSize: 14),
                        decoration:
                            const InputDecoration(hintText: 'e.g. India'),
                        validator: (v) {
                          if (v != null && v.length > 100) {
                            return 'Max 100 chars.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Travel style ─────────────────────────────────────────────────
            _FieldLabel('Travel Style'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _loading ? null : _pickTravelStyle,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _travelStyle == null ? AppColors.textSecondaryLight.withValues(alpha: 0.5) : AppColors.primary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _travelStyle == null
                          ? 'Select a travel style'
                          : (_travelStyles.firstWhere(
                              (s) => s['value'] == _travelStyle,
                              orElse: () => {'label': _travelStyle!},
                            )['label'] ?? _travelStyle!),
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: _travelStyle == null ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, color: AppColors.textSecondaryLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Languages ────────────────────────────────────────────────────
            _FieldLabel('Languages'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _langCtrl,
                    textInputAction: TextInputAction.done,
                    enabled: !_loading,
                    style: GoogleFonts.nunito(fontSize: 14),
                    decoration:
                        const InputDecoration(hintText: 'Add a language'),
                    onFieldSubmitted: (_) => _addLanguage(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _loading ? null : _addLanguage,
                  icon: const Icon(Icons.add_circle_rounded,
                      color: AppColors.primary),
                  tooltip: 'Add',
                ),
              ],
            ),
            if (_languages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _languages
                    .map(
                      (l) => Chip(
                        label: Text(
                          l,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: _loading ? null : () => _removeLanguage(l),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.09),
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.25)),
                        labelStyle:
                            const TextStyle(color: AppColors.primary),
                        deleteIconColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),

            // ── Budget ───────────────────────────────────────────────────────
            _FieldLabel('Preferred Budget (₹)'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetMinCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    enabled: !_loading,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.nunito(fontSize: 14),
                    decoration:
                        const InputDecoration(hintText: 'Min (e.g. 1000)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = double.tryParse(v);
                      if (n == null || n < 0) return 'Enter a valid amount.';
                      return null;
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('–'),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _budgetMaxCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    enabled: !_loading,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.nunito(fontSize: 14),
                    decoration:
                        const InputDecoration(hintText: 'Max (e.g. 8000)'),
                    onFieldSubmitted: (_) => _save(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = double.tryParse(v);
                      if (n == null || n < 0) return 'Enter a valid amount.';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── Save button ──────────────────────────────────────────────────
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field label
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryLight,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner
// ─────────────────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
