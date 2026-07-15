import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_inline_empty.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_timeline_header.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/timeline_stop_tile.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Route Details' ordered stop timeline: pickup/drop-off availability by
/// stop, with a graceful empty state when stations aren't published yet.
///
/// Sits on the same [ClientCard] surface as the rest of the sheet's sections
/// so the timeline reads as one continuous journey line instead of a stack of
/// separately tinted rows.
class RouteStopTimeline extends StatelessWidget {
  const RouteStopTimeline({super.key, required this.points});

  final List<RoutePointData> points;

  @override
  Widget build(BuildContext context) {
    final orderedPoints = [...points]
      ..sort((a, b) => a.order.compareTo(b.order));

    return ClientCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RouteTimelineHeader(stopCount: orderedPoints.length),
          if (orderedPoints.isEmpty) ...[
            const SizedBox(height: 16),
            RouteDetailsInlineEmpty(
              icon: Icons.alt_route_rounded,
              title: context.l10n.booking_stopsNotPublishedYet,
              subtitle: context.l10n.booking_routeStationsWillAppear,
            ),
          ] else ...[
            const SizedBox(height: 18),
            Divider(height: 1, color: ClientColors.borderFor(context)),
            const SizedBox(height: 18),
            ...orderedPoints.asMap().entries.map((entry) {
              return TimelineStopTile(
                point: entry.value,
                isFirst: entry.key == 0,
                isLast: entry.key == orderedPoints.length - 1,
              );
            }),
          ],
        ],
      ),
    );
  }
}
