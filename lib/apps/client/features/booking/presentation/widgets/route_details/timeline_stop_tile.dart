import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/stop_meta_labels.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/timeline_stop_dot.dart';

/// One stop row in `RouteStopTimeline`: rail marker, stop name, and a muted
/// caption saying what the passenger may do there.
///
/// The row is flat — no tinted card — so the eye scans the column of names
/// first and only then the supporting detail.
class TimelineStopTile extends StatelessWidget {
  const TimelineStopTile({
    super.key,
    required this.point,
    required this.isFirst,
    required this.isLast,
  });

  final RoutePointData point;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final kind = isFirst
        ? TimelineStopKind.origin
        : isLast
        ? TimelineStopKind.destination
        : TimelineStopKind.waypoint;
    final isEndpoint = kind != TimelineStopKind.waypoint;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TimelineStopDot(kind: kind, order: point.order, isLast: isLast),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1, bottom: isLast ? 0 : 22),
              child: _StopDetails(point: point, kind: kind, bold: isEndpoint),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopDetails extends StatelessWidget {
  const _StopDetails({
    required this.point,
    required this.kind,
    required this.bold,
  });

  final RoutePointData point;
  final TimelineStopKind kind;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = TimelineStopDot.accentFor(context, kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                point.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold
                      ? ClientColors.textPrimaryFor(context)
                      : ClientColors.textPrimaryFor(context).withAlpha(215),
                  letterSpacing: -0.2,
                  height: 1.25,
                ),
              ),
            ),
            if (kind != TimelineStopKind.waypoint) ...[
              const SizedBox(width: 10),
              StopRoleChip(
                label: kind == TimelineStopKind.origin ? 'Start' : 'End',
                color: accent,
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        StopCapabilityLabel(
          capability: StopCapability.of(
            pickupAllowed: point.pickupAllowed,
            dropoffAllowed: point.dropoffAllowed,
          ),
        ),
      ],
    );
  }
}
