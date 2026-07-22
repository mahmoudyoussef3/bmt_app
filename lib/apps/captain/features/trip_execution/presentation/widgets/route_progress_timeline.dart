import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';

enum _StopProgress { arrived, current, upcoming }

/// A read-only route visualization: every stop on this trip, marked arrived,
/// current, or upcoming against the live `arrivedStationsCount` — the same
/// arrival floor the "mark arrived" action (in the next-stop card) advances.
/// Purely a visualization; the action itself lives elsewhere so this stays
/// simple and never risks the optimistic-update logic that button owns.
class RouteProgressTimeline extends StatelessWidget {
  const RouteProgressTimeline({
    super.key,
    required this.stops,
    required this.arrivedStationsCount,
  });

  final List<AssignedTripStop> stops;
  final int arrivedStationsCount;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();
    final arrived = arrivedStationsCount.clamp(0, stops.length);

    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s20),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br20,
        boxShadow: CaptainDesignTokens.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stops.length; i++)
            _StopRow(
              name: stops[i].name,
              progress: i < arrived
                  ? _StopProgress.arrived
                  : i == arrived
                  ? _StopProgress.current
                  : _StopProgress.upcoming,
              isLast: i == stops.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.name,
    required this.progress,
    required this.isLast,
  });

  final String name;
  final _StopProgress progress;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (progress) {
      _StopProgress.arrived => CaptainColors.success,
      _StopProgress.current => CaptainColors.primary,
      _StopProgress.upcoming => CaptainColors.dividerFor(context),
    };
    final textColor = switch (progress) {
      _StopProgress.arrived => CaptainColors.textPrimaryFor(context),
      _StopProgress.current => CaptainColors.textPrimaryFor(context),
      _StopProgress.upcoming => CaptainColors.textSecondaryFor(context),
    };
    final fontWeight = progress == _StopProgress.current
        ? FontWeight.w800
        : FontWeight.w600;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: progress == _StopProgress.upcoming
                        ? Colors.transparent
                        : dotColor,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: progress == _StopProgress.arrived
                      ? const Icon(
                          Icons.check_rounded,
                          size: 9,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: progress == _StopProgress.arrived
                          ? CaptainColors.success
                          : CaptainColors.dividerFor(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : CaptainDesignTokens.s16,
              ),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.bodyMedium(
                  context,
                ).copyWith(fontWeight: fontWeight, color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
