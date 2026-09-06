import os

# 1. Append _DestinationsSection to profile_screen.dart
path_profile = r'D:\development\tripromio\lib\presentation\screens\profile\profile_screen.dart'
with open(path_profile, 'r', encoding='utf-8') as f:
    profile_code = f.read()

if 'class _DestinationsSection extends StatelessWidget' not in profile_code:
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
    with open(path_profile, 'w', encoding='utf-8') as f:
        f.write(profile_code + '\n' + new_section)
    print('Fixed profile_screen.dart')

# 2. Fix preferred_destinations_screen.dart issues
path_dest = r'D:\development\tripromio\lib\presentation\screens\profile\preferred_destinations_screen.dart'
with open(path_dest, 'r', encoding='utf-8') as f:
    dest_code = f.read()

dest_code = dest_code.replace(
    'onPopInvoked: (didPop) {',
    'onPopInvokedWithResult: (didPop, result) {'
)

dest_code = dest_code.replace(
    'separatorBuilder: (_, __) => const Divider(height: 1),',
    'separatorBuilder: (context, index) => const Divider(height: 1),'
)

with open(path_dest, 'w', encoding='utf-8') as f:
    f.write(dest_code)
print('Fixed preferred_destinations_screen.dart')
