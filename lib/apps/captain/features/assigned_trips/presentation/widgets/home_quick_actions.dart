import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

/// Fast shortcuts to the focus trip's most time-critical actions, so the
/// captain doesn't have to open the trip first to reach them.
///
/// Rendered as the focus card's footer strip. These were three standalone
/// bordered tiles sitting under the card — a third tier of floating boxes on a
/// screen that already had too many, and visually detached from the trip they
/// act on. As a footer they are unmistakably *this trip's* shortcuts, and they
/// cost the layout one divider instead of a whole row of cards.
///
/// Scoped to the trip's [stage]: these are in-trip tools, and offering
/// "الموقع" on a trip that hasn't left — or that operations hasn't even
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
      _QuickAction(
        icon: Icons.people_alt_rounded,
        label: 'الركاب',
        onTap: () => context.openPassengerManifest(tripId),
      ),
      // Location matters once the vehicle is actually moving passengers.
      if (stage == CaptainTripStage.underway)
        _QuickAction(
          icon: Icons.my_location_rounded,
          label: 'الموقع',
          onTap: () => context.openLocationUpdate(tripId),
        ),
      // From the moment the captain is at the stop, a breakdown or a delay is
      // reportable — it doesn't wait for departure.
      if (!stage.isWaiting)
        _QuickAction(
          icon: Icons.report_problem_outlined,
          label: 'بلاغ طارئ',
          destructive: true,
          onTap: () => context.openReportIncident(tripId),
        ),
    ];

    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const _Separator(),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: CaptainDesignTokens.s12,
      endIndent: CaptainDesignTokens.s12,
      color: CaptainColors.dividerFor(context).withValues(alpha: 0.7),
    );
  }
}

/// A footer shortcut: icon beside label on one line, so the strip stays short
/// enough to be a footer rather than a fourth block of content.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
    final color = destructive
        ? CaptainColors.error
        : CaptainColors.textPrimaryFor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: CaptainDesignTokens.s16,
            horizontal: CaptainDesignTokens.s8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: destructive
                    ? CaptainColors.error
                    : CaptainColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.labelMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
