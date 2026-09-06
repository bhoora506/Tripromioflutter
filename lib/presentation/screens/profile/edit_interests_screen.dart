import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/interest_model.dart';
import '../../../data/services/profile_service.dart';

class EditInterestsScreen extends StatefulWidget {
  const EditInterestsScreen({
    super.key,
    required this.currentInterests,
  });

  final List<InterestModel> currentInterests;

  @override
  State<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen> {
  final _service = ProfileService();
  
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  
  List<InterestModel> _masterList = [];
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Preselect current user's interests
    for (final interest in widget.currentInterests) {
      _selectedIds.add(interest.id);
    }
    _fetchMasterList();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchMasterList() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await _service.getInterests();
      if (!mounted) return;
      setState(() {
        _masterList = list;
        _errorMessage = null;
      });
    } on NetworkException {
      if (mounted) {
        setState(() => _errorMessage = 'No internet connection. Please retry.');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSelection(int id) {
    if (_saving) return;

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 20) {
          _showSnack('You can select a maximum of 20 interests.');
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final updatedUser = await _service.updateInterests(_selectedIds.toList());
      if (!mounted) return;
      _showSnack('Interests updated successfully!', isSuccess: true);
      // Return updated user to ProfileScreen so it updates immediately
      Navigator.of(context).pop(updatedUser);
    } on ValidationException catch (e) {
      final msgs = (e.errors?.values.expand((v) => v).join('\n')) ?? e.message;
      if (mounted) _showSnack(msgs);
    } on UnauthorizedException {
      if (mounted) _showSnack('Session expired. Please log in again.');
    } on NetworkException {
      if (mounted) _showSnack('No internet connection. Please retry.');
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimaryLight,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Interests',
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
              onPressed: (_loading || _saving || _errorMessage != null)
                  ? null
                  : _save,
              child: _saving
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _ErrorBody(message: _errorMessage!, onRetry: _fetchMasterList)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Text(
          'What are you interested in?',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select up to 20 interests to help us find the best travel companions for you.',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: _masterList.map((interest) {
            final isSelected = _selectedIds.contains(interest.id);
            return FilterChip(
              label: Text(
                interest.name,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textPrimaryLight,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _toggleSelection(interest.id),
              backgroundColor: AppColors.surfaceLight,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderLight,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.textSecondaryLight,
            ),
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
