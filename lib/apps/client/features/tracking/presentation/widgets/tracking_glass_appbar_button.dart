import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// Frosted circular app bar action, used in place of a bare icon when the
/// app bar floats over a full-bleed map: a plain [IconButton] can vanish
/// against light tiles, so this gives it the same glass chip treatment as
/// the map's own chrome ([GlassInfoCard], [MapControlCluster]).
class TrackingGlassAppBarButton extends StatelessWidget {
  const TrackingGlassAppBarButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: MapStyle.surface(context).withAlpha(isDark ? 200 : 222),
            shape: CircleBorder(side: BorderSide(color: MapStyle.border(context))),
            child: IconButton(
              icon: Icon(icon, color: MapStyle.onSurface(context)),
              tooltip: tooltip,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}
