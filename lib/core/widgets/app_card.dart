import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_surface_style.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        theme.extension<AppSurfaceStyle>() ??
        AppSurfaceStyle.flat(theme.colorScheme);
    final radius = BorderRadius.circular(style.radius);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: radius,
        border: Border.all(color: style.borderColor),
        boxShadow: style.shadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(onTap: onTap, borderRadius: radius, child: card),
      );
    }

    return card;
  }
}
