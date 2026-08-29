import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/driver_profile.dart';

/// The captain's record: a figure over the word for it, in the same tiles the
/// home screen counts the day in.
///
/// Deliberately the same shape as `AssignedTripsStatsStrip` — home states
/// today, the profile states the career, and a captain reading both should not
/// have to learn two ways of showing a number. Home draws its tiles neutral
/// because one of them can turn amber for a live trip; nothing here ever needs
/// acting on, so the whole strip is free to sit in the brand tint.
class DriverProfileStatsCard extends StatelessWidget {
  const DriverProfileStatsCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final hireDate = profile.hireDate;
    final tiles = <Widget>[
      _Tile(value: '${profile.totalTrips}', label: 'رحلة مكتملة'),
      _Tile(value: '${profile.totalPassengers}', label: 'راكب نُقلوا'),
      if (hireDate != null)
        _Tile(value: '${hireDate.year}', label: 'كابتن منذ'),
    ];

    // IntrinsicHeight, not `CrossAxisAlignment.stretch`: the strip is laid out
    // in an unbounded-height list, where stretch asks each tile to be
    // infinitely tall. This keeps the tiles level when one label wraps.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            tiles[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: CaptainDesignTokens.s12,
          horizontal: CaptainDesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: CaptainColors.primary.withValues(alpha: 0.07),
          borderRadius: CaptainDesignTokens.br16,
          border: Border.all(
            color: CaptainColors.primary.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: CaptainTypography.titleLarge(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: CaptainColors.primaryInkFor(context),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CaptainTypography.labelSmall(context).copyWith(
                // The caption stays a step under its figure — same hue, less
                // ink — so the number still reads first.
                color: CaptainColors.primaryInkFor(
                  context,
                ).withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
