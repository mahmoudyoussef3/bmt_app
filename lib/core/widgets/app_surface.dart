import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_surface_style.dart';

/// AppSurface: lightweight, reusable surface with consistent radius, padding,
/// border and soft elevation used throughout the app for cards and panels.
class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style =
        theme.extension<AppSurfaceStyle>() ?? AppSurfaceStyle.flat(cs);
    final bg = color ?? theme.cardColor;

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: style.borderColor),
        boxShadow: style.shadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: container,
        ),
      );
    }

    return container;
  }
}
