import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_surface.dart';

/// Consistent empty state for list/tab screens.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.spaceXl,
        vertical: AppLayout.spaceXxl,
      ),
      radius: AppLayout.radiusLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: scheme.primary.withAlpha(180)),
          const SizedBox(height: AppLayout.spaceLg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.subheading(scheme),
          ),
          if (message != null) ...[
            const SizedBox(height: AppLayout.spaceSm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.caption(
                scheme,
              ).copyWith(color: scheme.onSurface.withAlpha(170)),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppLayout.spaceLg),
            action!,
          ],
        ],
      ),
    );
  }
}
