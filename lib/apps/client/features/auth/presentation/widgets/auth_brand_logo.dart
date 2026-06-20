import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Shared horizontal brand mark (app-icon tile + "EasyWay" wordmark) used as the
/// header logo on every auth screen. Replaces the per-screen private copies.
class AuthBrandLogo extends StatelessWidget {
  const AuthBrandLogo({super.key, this.tileSize = 46});

  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: tileSize,
          width: tileSize,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: ClientColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.primary.withAlpha(46)),
          ),
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.directions_bus_rounded,
              color: ClientColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'EasyWay',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: ClientColors.primary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
