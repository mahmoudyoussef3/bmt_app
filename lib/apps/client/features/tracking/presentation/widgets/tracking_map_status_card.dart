import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/vehicle_sample.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/maps/overlays/glass_info_card.dart';

import '../../domain/entities/tracking_trip.dart';
import 'tracking_map_status_badges.dart';
import 'tracking_map_status_rows.dart';

/// The single floating card on the live map. It leads with the question a
/// rider actually opens the map to answer — which stop the bus is heading to
/// and how long that takes — and keeps the driver's identity as the quiet
/// second line. The card it replaced led with "Live — 2 min ago", which is a
/// fact about our GPS pipeline, not about the rider's trip.
class TrackingMapStatusCard extends StatelessWidget {
  const TrackingMapStatusCard({
    super.key,
    required this.driverInitials,
    required this.driverName,
    required this.vehiclePlate,
    required this.currentState,
    this.progress,
    this.sample,
  });

  final String driverInitials;
  final String driverName;
  final String vehiclePlate;
  final TrackingTripState currentState;
  final RouteProgressSnapshot? progress;
  final VehicleSample? sample;

  bool get _completed => currentState == TrackingTripState.completed;

  @override
  Widget build(BuildContext context) {
    final nextStop = progress?.nextStop;
    return GlassInfoCard(
      maxWidth: 264,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_completed)
            const TrackingHeadlineRow(
              icon: Icons.flag_rounded,
              tone: ClientColors.journeyGreen,
              caption: 'Trip',
              title: 'Completed',
            )
          else if (nextStop != null)
            TrackingHeadlineRow(
              icon: Icons.near_me_rounded,
              tone: ClientColors.primary,
              caption: 'Next stop',
              title: nextStop.stop.name,
              trailing: TrackingEtaBadge(eta: nextStop.eta),
            )
          else
            TrackingHeadlineRow(
              icon: Icons.location_searching_rounded,
              tone: ClientColors.journeySlate,
              caption: 'Next stop',
              title: 'Waiting for the bus',
            ),
          const SizedBox(height: 10),
          Divider(height: 1, color: MapStyle.border(context)),
          const SizedBox(height: 10),
          TrackingDriverRow(
            initials: driverInitials,
            name: driverName,
            plate: vehiclePlate,
            trailing: TrackingSignalChip(
              sample: sample,
              completed: _completed,
            ),
          ),
        ],
      ),
    );
  }
}
