import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Temporary placeholder used by [AppRouter] for every route that has not
/// been implemented yet. It shows the route label so navigation can be
/// tested end-to-end before real screens are built.
///
/// Replace usages in [AppRouter] as real screens are introduced.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingH,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                label,
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'This screen is coming in a future phase.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
