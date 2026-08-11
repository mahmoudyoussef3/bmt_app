import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_brand_mark.dart';

class CaptainAuthHeader extends StatelessWidget {
  const CaptainAuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.directions_bus_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CaptainBrandMark(icon: icon),
        const SizedBox(height: CaptainDesignTokens.s24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: CaptainTypography.headlineMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: CaptainDesignTokens.s8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: CaptainTypography.bodyMedium(
            context,
          ).copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
