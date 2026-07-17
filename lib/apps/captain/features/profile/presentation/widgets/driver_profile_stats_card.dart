import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

import '../../domain/entities/driver_profile.dart';

/// The captain's lifetime totals.
///
/// These used to sit on glass tiles inside the header, which is what forced the
/// header tall. On a surface card they carry full-contrast text instead of
/// white-on-gradient, and they match the stats strip the trips tab already
/// uses — the same numbers should look the same wherever the captain meets them.
class DriverProfileStatsCard extends StatelessWidget {
  const DriverProfileStatsCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s20,
      ),
      child: Row(
        children: [
          _Stat(
            icon: Icons.route_rounded,
            value: '${profile.totalTrips}',
            label: 'رحلة مكتملة',
            color: CaptainColors.primary,
          ),
          const _Divider(),
          _Stat(
            icon: Icons.people_alt_rounded,
            value: '${profile.totalPassengers}',
            label: 'راكب نُقلوا',
            color: CaptainColors.primaryBright,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: CaptainDesignTokens.s8),
          Text(
            value,
            maxLines: 1,
            style: CaptainTypography.headlineSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.labelSmall(
              context,
            ).copyWith(color: CaptainColors.textSecondaryFor(context)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: CaptainColors.dividerFor(context),
    );
  }
}
