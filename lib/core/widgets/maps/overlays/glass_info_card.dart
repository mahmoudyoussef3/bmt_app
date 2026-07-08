import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// Frosted, elevated card shell used for every floating overlay on an EasyWay
/// map: the route info panel, ETA-adjacent chrome and the Captain Card. Only
/// the chrome lives here — callers compose their own content as [child].
class GlassInfoCard extends StatelessWidget {
  const GlassInfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.maxWidth,
    this.borderRadius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: maxWidth == null
              ? null
              : BoxConstraints(maxWidth: maxWidth!),
          padding: padding,
          decoration: BoxDecoration(
            color: MapStyle.surface(context).withAlpha(isDark ? 200 : 222),
            borderRadius: radius,
            border: Border.all(color: MapStyle.border(context)),
            boxShadow: MapStyle.shadow(context),
          ),
          child: child,
        ),
      ),
    );
  }
}
