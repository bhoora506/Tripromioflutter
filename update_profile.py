import os

path = r'D:\development\tripromio\lib\presentation\screens\profile\profile_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add import
if 'preferred_destination_model.dart' not in code:
    code = code.replace(
        "import '../../../data/models/user_model.dart';",
        "import '../../../data/models/user_model.dart';\nimport '../../../data/models/preferred_destination_model.dart';"
    )

# 2. Add state variables
if '_destinations' not in code:
    code = code.replace(
        '''  bool _photoUploading = false;
  String? _errorMessage;''',
        '''  bool _photoUploading = false;
  String? _errorMessage;
  List<PreferredDestinationModel>? _destinations;
  String? _destinationsError;'''
    )

# 3. Update _load
new_load = '''  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _destinationsError = null;
    });
    
    try {
      // Load user profile
      final user = await _service.getProfile();
      
      // Try to load destinations, but don't fail profile if it fails
      List<PreferredDestinationModel>? destList;
      String? destErr;
      try {
        destList = await _service.getPreferredDestinations();
      } catch (e) {
        destErr = 'Failed to load destinations.';
      }
      
      if (!mounted) return;
      setState(() {
        _user = user;
        _destinations = destList;
        _destinationsError = destErr;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() => _errorMessage = 'No internet connection. Please retry.');
    } on UnauthorizedException {
      if (!mounted) return;
      setState(
          () => _errorMessage = 'Session expired. Please log in again.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }'''
code = code.split('  Future<void> _load() async {')[0] + new_load + code.split('  } finally {\n      if (mounted) setState(() => _loading = false);\n    }\n  }')[1]

# 4. Add _openDestinations
new_nav = '''
  Future<void> _openDestinations() async {
    final updated = await Navigator.of(context).pushNamed(
      AppRoutes.preferredDestinations,
    );
    if (updated is List<PreferredDestinationModel> && mounted) {
      setState(() => _destinations = updated);
    }
  }

  // ── Photo edit bottom sheet'''
code = code.replace('  // ── Photo edit bottom sheet', new_nav)

# 5. Update _ProfileBody constructor
code = code.replace(
    '''  const _ProfileBody({
    required this.user,
    required this.photoUploading,
    required this.onEdit,
    required this.onPhotoEdit,
    required this.onEditInterests,
  });

  final UserModel user;
  final bool photoUploading;
  final VoidCallback onEdit;
  final VoidCallback onPhotoEdit;
  final VoidCallback onEditInterests;''',
    '''  const _ProfileBody({
    required this.user,
    required this.photoUploading,
    required this.onEdit,
    required this.onPhotoEdit,
    required this.onEditInterests,
    required this.onEditDestinations,
    required this.destinations,
    required this.destinationsError,
  });

  final UserModel user;
  final bool photoUploading;
  final VoidCallback onEdit;
  final VoidCallback onPhotoEdit;
  final VoidCallback onEditInterests;
  final VoidCallback onEditDestinations;
  final List<PreferredDestinationModel>? destinations;
  final String? destinationsError;'''
)

# 6. Update _ProfileBody build usage
code = code.replace(
    '''                  onEdit: _openEdit,
                  onPhotoEdit: _showPhotoOptions,
                  onEditInterests: _openEditInterests,
                ),''',
    '''                  onEdit: _openEdit,
                  onPhotoEdit: _showPhotoOptions,
                  onEditInterests: _openEditInterests,
                  onEditDestinations: _openDestinations,
                  destinations: _destinations,
                  destinationsError: _destinationsError,
                ),'''
)

# 7. Add Destinations section to CustomScrollView
code = code.replace(
    '''        SliverToBoxAdapter(child: _TravelSection(user: user, onEditInterests: onEditInterests)),
        SliverToBoxAdapter(child: _BudgetSection(user: user)),''',
    '''        SliverToBoxAdapter(child: _TravelSection(user: user, onEditInterests: onEditInterests)),
        SliverToBoxAdapter(child: _DestinationsSection(
          destinations: destinations, 
          error: destinationsError, 
          onEdit: onEditDestinations,
        )),
        SliverToBoxAdapter(child: _BudgetSection(user: user)),'''
)

# 8. Add _DestinationsSection class
new_section = '''
// ─────────────────────────────────────────────────────────────────────────────
// Preferred Destinations Section
// ─────────────────────────────────────────────────────────────────────────────

class _DestinationsSection extends StatelessWidget {
  const _DestinationsSection({
    required this.destinations,
    required this.error,
    required this.onEdit,
  });

  final List<PreferredDestinationModel>? destinations;
  final String? error;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _Section(
        title: 'Preferred Destinations',
        icon: Icons.place_rounded,
        onEdit: onEdit,
        children: [
          Text(
            error!,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.error,
            ),
          ),
        ],
      );
    }

    if (destinations == null || destinations!.isEmpty) {
      return _Section(
        title: 'Preferred Destinations',
        icon: Icons.place_rounded,
        onEdit: onEdit,
        children: [
          Text(
            'No destinations added yet.',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return _Section(
      title: 'Preferred Destinations',
      icon: Icons.place_rounded,
      onEdit: onEdit,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: destinations!.map((d) => _Tag(label: d.destination)).toList(),
        ),
      ],
    );
  }
}
'''
if '_DestinationsSection' not in code:
    code = code + '\n' + new_section

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)

print('Updated profile_screen.dart')
