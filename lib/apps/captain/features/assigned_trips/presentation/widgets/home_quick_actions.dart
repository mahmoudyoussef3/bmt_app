import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

/// Fast shortcuts to the focus trip's most time-critical actions, so the
/// captain doesn't have to open the trip first to reach them.
///
/// Scoped to the trip's [stage]: these are in-trip tools, and offering
/// "إرسال الموقع" on a trip that hasn't left — or that operations hasn't even
/// published — asks the captain to broadcast a position for a journey that
/// isn't happening. Before boarding, the only thing worth a shortcut is who
/// has booked a seat.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.tripId,
    required this.stage,
  });

  final String tripId;
  final CaptainTripStage stage;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _QuickActionTile(
        icon: Icons.people_alt_rounded,
        label: 'كشف الركاب',
        onTap: () => context.openPassengerManifest(tripId),
      ),
      // Location matters once the vehicle is actually moving passengers.
      if (stage == CaptainTripStage.underway)
        _QuickActionTile(
          icon: Icons.my_location_rounded,
          label: 'إرسال الموقع',
          onTap: () => context.openLocationUpdate(tripId),
        ),
      // From the moment the captain is at the stop, a breakdown or a delay is
      // reportable — it doesn't wait for departure.
      if (!stage.isWaiting)
        _QuickActionTile(
          icon: Icons.report_problem_outlined,
          label: 'بلاغ طارئ',
          destructive: true,
          onTap: () => context.openReportIncident(tripId),
        ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? CaptainColors.error : CaptainColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CaptainDesignTokens.br16,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: CaptainDesignTokens.s12,
          ),
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br16,
            border: Border.all(
              color: destructive
                  ? CaptainColors.error.withValues(alpha: 0.15)
                  : CaptainColors.dividerFor(context),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.labelSmall(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: destructive
                      ? CaptainColors.error
                      : CaptainColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
