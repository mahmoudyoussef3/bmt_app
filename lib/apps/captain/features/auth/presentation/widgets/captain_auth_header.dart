import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// Brand lockup + title/subtitle used at the top of captain auth screens.
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
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.primary.withAlpha(200)],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withAlpha(70),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(icon, size: 42, color: scheme.onPrimary),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: CaptainTypography.headlineMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
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
