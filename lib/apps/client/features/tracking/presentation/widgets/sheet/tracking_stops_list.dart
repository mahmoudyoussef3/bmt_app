import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';
import 'package:bmt_app/core/tracking/progress/station_overlay.dart';
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
///
/// Once the trip is running, the captain's station board is laid over the
/// GPS-inferred states: a stop they have actually left reads "تم المرور"
/// whatever the last fix suggested. A rider who has boarded keeps this list —
/// they lose the vehicle's position, not their journey — and their ETAs come
/// from the board's projection instead of live GPS, which is why they are
/// captioned "حسب الجدول" rather than "من الموقع المباشر".
class TrackingStopsList extends StatelessWidget {
  const TrackingStopsList({
    super.key,
    required this.progress,
    required this.rider,
    required this.labels,
    this.stations = const StationBoard.empty(),
    this.now,
  });

  final RouteProgressSnapshot? progress;
  final TrackingRider rider;
  final TrackingLabels labels;
  final StationBoard stations;

  /// Injected in tests so the projected ETAs are deterministic.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final inferred = progress?.stops ?? const <StopProgress>[];
    if (inferred.isEmpty) return const SizedBox.shrink();

    final stops = overlayStationBoard(
      inferred: inferred,
      board: stations,
      now: now ?? DateTime.now(),
      // A boarded rider has no live positions to derive an ETA from, so the
      // board's schedule-plus-observed-delay projection is the best honest
      // number available to them.
      preferLiveEta: rider.canTrackVehicle,
    );

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
        const SizedBox(height: 8),
        // Said once, at the bottom, rather than next to every number: these are
        // estimates and the road decides.
        Text(
          labels.l10n.tracking_etaMayChange,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
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
