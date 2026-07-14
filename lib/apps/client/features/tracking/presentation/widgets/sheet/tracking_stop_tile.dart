import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import '../../formatters/tracking_labels.dart';
import 'tracking_stop_tile_parts.dart';

/// One stop in the timeline: a rail dot, the stop's name, its live state, and
/// its ETA.
///
/// Stops the rider actually travels through are full strength; the ones outside
/// their leg are dimmed, because they belong to other passengers' journeys. They
/// are still shown, though — they are *why* the trip takes as long as it does.
class TrackingStopTile extends StatelessWidget {
  const TrackingStopTile({
    super.key,
    required this.stop,
    required this.labels,
    required this.isFirst,
    required this.isLast,
    required this.onRiderLeg,
    this.badge,
  });

  final StopProgress stop;
  final TrackingLabels labels;
  final bool isFirst;
  final bool isLast;
  final bool onRiderLeg;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final status = labels.stopStatus(stop.status);
    final eta = stop.isVisited ? null : labels.clock(stop.eta);
    final caption = [
      status,
      ?eta,
    ].where((part) => part.isNotEmpty).join(' · ');

    return Opacity(
      opacity: onRiderLeg ? 1 : 0.45,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrackingStopRail(
              color: _color(context),
              status: stop.status,
              isFirst: isFirst,
              isLast: isLast,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            stop.stop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.bodyMedium(context)
                                .copyWith(
                                  fontWeight: badge != null
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          TrackingStopBadge(text: badge!),
                        ],
                      ],
                    ),
                    if (caption.isNotEmpty)
                      Text(
                        caption,
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: ClientColors.textTertiaryFor(context),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _color(BuildContext context) => switch (stop.status) {
    StopVisitStatus.departed => ClientColors.journeySlate,
    StopVisitStatus.arrived ||
    StopVisitStatus.next => ClientColors.primaryFor(context),
    StopVisitStatus.upcoming => ClientColors.borderStrongFor(context),
  };
}
