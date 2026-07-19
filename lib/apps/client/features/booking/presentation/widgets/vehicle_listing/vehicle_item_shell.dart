import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Wraps a vehicle card with a selected-state highlight border.
class VehicleItemShell extends StatelessWidget {
  const VehicleItemShell({
    super.key,
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: selected ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: selected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: ClientColors.primary, width: 1.6),
            )
          : null,
      child: child,
    );
  }
}
