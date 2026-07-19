import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Rounded soft-tinted icon chip used across the vehicle detail cards.
class VehicleSoftIcon extends StatelessWidget {
  const VehicleSoftIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Thin vertical divider between stat columns.
class VehicleStatDivider extends StatelessWidget {
  const VehicleStatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: ClientColors.borderFor(context),
    );
  }
}
