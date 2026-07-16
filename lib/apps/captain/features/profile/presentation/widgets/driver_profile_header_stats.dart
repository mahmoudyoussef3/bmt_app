import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// Lifetime totals, on glass tiles over the header gradient.
class DriverProfileHeaderStats extends StatelessWidget {
  const DriverProfileHeaderStats({
    super.key,
    required this.totalTrips,
    required this.totalPassengers,
  });

  final int totalTrips;
  final int totalPassengers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        children: [
          _StatTile(
            label: 'رحلات',
            value: '$totalTrips',
            icon: Icons.route_rounded,
          ),
          const _StatDivider(),
          _StatTile(
            label: 'ركاب',
            value: '$totalPassengers',
            icon: Icons.people_alt_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white.withAlpha(45));
  }
}

/// A single lifetime total. Only ever rendered on the header gradient, so it
/// commits to on-primary colours rather than carrying a light/dark switch.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withAlpha(200), size: 14),
              const SizedBox(width: CaptainDesignTokens.s4),
              Text(
                label,
                style: CaptainTypography.labelSmall(
                  context,
                ).copyWith(color: Colors.white.withAlpha(200)),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s4),
          Text(
            value,
            style: CaptainTypography.headlineSmall(context).copyWith(
              fontWeight: FontWeight.w900,
              color: CaptainColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
