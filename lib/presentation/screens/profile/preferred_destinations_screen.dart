import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/preferred_destination_model.dart';
import '../../../data/services/profile_service.dart';

class PreferredDestinationsScreen extends StatefulWidget {
  const PreferredDestinationsScreen({super.key});

  @override
  State<PreferredDestinationsScreen> createState() =>
      _PreferredDestinationsScreenState();
}

class _PreferredDestinationsScreenState
    extends State<PreferredDestinationsScreen> {
  final _service = ProfileService();
  bool _loading = true;
  String? _errorMessage;
  List<PreferredDestinationModel> _destinations = [];

  @override
  void initState() {
    super.initState();
    _fetchDestinations();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchDestinations() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await _service.getPreferredDestinations();
      if (!mounted) return;
      setState(() {
        _destinations = list;
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
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _confirmDelete(PreferredDestinationModel dest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this destination?'),
        content: Text(
            'Are you sure you want to remove ${dest.destination} from your preferred destinations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _deleteDestination(dest.id);
    }
  }

  Future<void> _deleteDestination(int id) async {
    setState(() => _loading = true);
    try {
      await _service.deletePreferredDestination(id);
      if (!mounted) return;
      setState(() {
        _destinations.removeWhere((d) => d.id == id);
      });
      _showSnack('Preferred destination deleted successfully', isSuccess: true);
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDestinationForm({PreferredDestinationModel? dest}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _DestinationForm(
          service: _service,
          existingDest: dest,
          onSuccess: (newDest) {
            setState(() {
              if (dest == null) {
                _destinations.add(newDest);
              } else {
                final index = _destinations.indexWhere((d) => d.id == dest.id);
                if (index != -1) {
                  _destinations[index] = newDest;
                }
              }
            });
            _showSnack('Destination saved successfully', isSuccess: true);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_destinations);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimaryLight,
            onPressed: () => Navigator.of(context).pop(_destinations),
          ),
          title: Text(
            'Preferred Destinations',
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
        ),
        body: _loading && _destinations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _destinations.isEmpty
                ? _ErrorBody(
                    message: _errorMessage!, onRetry: _fetchDestinations)
                : _buildContent(),
        floatingActionButton: _destinations.length >= 50
            ? null
            : FloatingActionButton(
                onPressed: () => _showDestinationForm(),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildContent() {
    if (!_loading && _destinations.isEmpty && _errorMessage == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.place_outlined,
                size: 56,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                'No preferred destinations yet.',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add places you would love to travel to!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: _destinations.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final dest = _destinations[index];
            return ListTile(
              title: Text(
                dest.destination,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    color: AppColors.textSecondaryLight,
                    onPressed: () => _showDestinationForm(dest: dest),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: AppColors.error,
                    onPressed: () => _confirmDelete(dest),
                  ),
                ],
              ),
            );
          },
        ),
        if (_loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
        if (_destinations.length >= 50)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                'You have reached the maximum of 50 preferred destinations.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DestinationForm extends StatefulWidget {
  const _DestinationForm({
    required this.service,
    this.existingDest,
    required this.onSuccess,
  });

  final ProfileService service;
  final PreferredDestinationModel? existingDest;
  final ValueChanged<PreferredDestinationModel> onSuccess;

  @override
  State<_DestinationForm> createState() => _DestinationFormState();
}

class _DestinationFormState extends State<_DestinationForm> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingDest?.destination);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Destination name is required');
      return;
    }
    if (text.length > 200) {
      setState(() => _error = 'Destination name cannot exceed 200 characters');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      PreferredDestinationModel result;
      if (widget.existingDest == null) {
        result = await widget.service.addPreferredDestination(text);
      } else {
        result = await widget.service
            .updatePreferredDestination(widget.existingDest!.id, text);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess(result);
    } on ValidationException catch (e) {
      final msgs = (e.errors?.values.expand((v) => v).join('\n')) ?? e.message;
      if (mounted) setState(() => _error = msgs);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existingDest == null ? 'Add Destination' : 'Edit Destination',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Destination Name',
              hintText: 'e.g., Manali',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            enabled: !_saving,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.existingDest == null ? 'Add' : 'Save Changes',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
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
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
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
