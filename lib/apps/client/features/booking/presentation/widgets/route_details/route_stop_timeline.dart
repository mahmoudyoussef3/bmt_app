import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_inline_empty.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/timeline_stop_tile.dart';

/// Route Details' ordered stop timeline: pickup/drop-off availability by
/// stop, with a graceful empty state when stations aren't published yet.
class RouteStopTimeline extends StatelessWidget {
  const RouteStopTimeline({super.key, required this.points});

  final List<RoutePointData> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final orderedPoints = [...points]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ClientColors.primaryContainerFor(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: ClientColors.primaryFor(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route timeline',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pickup and drop-off availability by stop',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: const RouteDetailsInlineEmpty(
                icon: Icons.alt_route_rounded,
                title: 'Stops are not published yet',
                subtitle: 'Route stations will appear here once available.',
              ),
            )
          else
            ...orderedPoints.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              return TimelineStopTile(
                point: point,
                isFirst: index == 0,
                isLast: index == orderedPoints.length - 1,
              );
            }),
        ],
      ),
    );
  }
}
