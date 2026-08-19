import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

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
