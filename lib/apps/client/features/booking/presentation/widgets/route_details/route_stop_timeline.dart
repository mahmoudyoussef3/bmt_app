import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_inline_empty.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_timeline_header.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/timeline_stop_tile.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Route Details' ordered stop timeline: every station the line serves, in
/// order, saying what a passenger may do at each — with a graceful empty state
/// when the operator has not published stations yet.
///
/// This is the screen's main content now that fares, departures-to-pick,
/// packages and the operator have moved into the booking steps that actually
/// decide them. Stations are the one thing a rider needs *before* committing
/// to a line, so they get the room.
class RouteStopTimeline extends StatelessWidget {
  const RouteStopTimeline({
    super.key,
    required this.points,
    required this.onEditStops,
  });

  final List<RoutePointData> points;

  /// Opens the map picker so a rider who is on the wrong line can change the
  /// stations they searched with. It sits with the stations rather than beside
  /// the screen title, because that is the content it edits.
  final VoidCallback onEditStops;

  @override
  Widget build(BuildContext context) {
    final orderedPoints = [...points]
      ..sort((a, b) => a.order.compareTo(b.order));

    return ClientCard(
      padding: ClientSpacing.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RouteTimelineHeader(stopCount: orderedPoints.length),
          const SizedBox(height: 16),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          const SizedBox(height: 18),
          if (orderedPoints.isEmpty)
            RouteDetailsInlineEmpty(
              icon: Icons.alt_route_rounded,
              title: context.l10n.booking_stopsNotPublishedYet,
              subtitle: context.l10n.booking_routeStationsWillAppear,
            )
          else
            ...orderedPoints.asMap().entries.map(
              (entry) => TimelineStopTile(
                point: entry.value,
                isFirst: entry.key == 0,
                isLast: entry.key == orderedPoints.length - 1,
              ),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onEditStops,
              icon: const Icon(Icons.edit_location_alt_rounded, size: 17),
              label: Text(context.l10n.booking_editStops),
              style: TextButton.styleFrom(
                foregroundColor: ClientColors.primaryFor(context),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
                textStyle: ClientTypography.labelMedium(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
