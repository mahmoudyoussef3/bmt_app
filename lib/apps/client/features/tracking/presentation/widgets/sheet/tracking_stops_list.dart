import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import '../../../domain/entities/tracking_rider.dart';
import '../../formatters/tracking_labels.dart';
import 'tracking_stop_tile.dart';

/// The trip's stops, in route order, with the rider's own two badged.
///
/// Order comes from `point_order` and is fixed in the data layer — the list
/// renders exactly what it is given. The rider's boarding and drop-off stops
/// are matched by id, so the badges land on the right rows even when two
/// stations share a name.
class TrackingStopsList extends StatelessWidget {
  const TrackingStopsList({
    super.key,
    required this.progress,
    required this.rider,
    required this.labels,
  });

  final RouteProgressSnapshot? progress;
  final TrackingRider rider;
  final TrackingLabels labels;

  @override
  Widget build(BuildContext context) {
    final stops = progress?.stops ?? const <StopProgress>[];
    if (stops.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels.l10n.tracking_stopsTitle,
          style: ClientTypography.labelMedium(context),
        ),
        const SizedBox(height: 8),
        ClientCard(
          child: Column(
            children: [
              for (final (index, stop) in stops.indexed)
                TrackingStopTile(
                  stop: stop,
                  labels: labels,
                  isFirst: index == 0,
                  isLast: index == stops.length - 1,
                  onRiderLeg: rider.isOnRiderLeg(index),
                  badge: _badge(index),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String? _badge(int index) {
    if (rider.isBoardingStop(index)) return labels.l10n.tracking_yourStopBadge;
    if (rider.isDropoffStop(index)) {
      return labels.l10n.tracking_yourDropoffBadge;
    }
    return null;
  }
}
