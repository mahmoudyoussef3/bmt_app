import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_metrics.dart';

class DriverProfileStatsCard extends StatelessWidget {
  const DriverProfileStatsCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tile(
          icon: Icons.route_rounded,
          value: '${profile.totalTrips}',
          label: 'رحلة مكتملة',
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        _Tile(
          icon: Icons.people_alt_rounded,
          value: '${profile.totalPassengers}',
          label: 'راكب نُقلوا',
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(
          minHeight: DriverProfileMetrics.statTileHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: CaptainDesignTokens.s12,
          vertical: CaptainDesignTokens.s12,
        ),
        decoration: BoxDecoration(
          color: CaptainColors.primary.withAlpha(14),
          borderRadius: CaptainDesignTokens.br20,
          border: Border.all(color: CaptainColors.primary.withAlpha(30)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: CaptainColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaptainTypography.labelSmall(context).copyWith(
                      color: CaptainColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: CaptainTypography.headlineSmall(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: CaptainColors.textPrimaryFor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
