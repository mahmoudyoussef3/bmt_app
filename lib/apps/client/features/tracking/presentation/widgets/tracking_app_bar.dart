import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_glass_appbar_button.dart';

/// The tracking screen's app bar. Active states float it, transparent, over
/// a full-bleed map — the sheet below already headlines the same status
/// text, so the title is dropped there to avoid clutter and a collision
/// with the floating captain card just under it, and chrome gets a glass
/// backdrop so it stays legible over any map tile color.
class TrackingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TrackingAppBar({
    super.key,
    required this.isActive,
    required this.title,
    required this.showPreviewAction,
    required this.onPreviewStates,
    required this.onRefresh,
  });

  final bool isActive;
  final String title;
  final bool showPreviewAction;
  final VoidCallback onPreviewStates;
  final VoidCallback onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: isActive
          ? null
          : Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
      leading: isActive
          ? TrackingGlassAppBarButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: [
        isActive
            ? TrackingGlassAppBarButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onPressed: onRefresh,
              )
            : IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: onRefresh,
              ),
        if (showPreviewAction)
          isActive
              ? TrackingGlassAppBarButton(
                  icon: Icons.tune_rounded,
                  tooltip: 'Preview trip states',
                  onPressed: onPreviewStates,
                )
              : IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Preview trip states',
                  onPressed: onPreviewStates,
                ),
      ],
      elevation: 0,
      backgroundColor: isActive
          ? Colors.transparent
          : ClientColors.surfaceFor(context),
    );
  }
}
