import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_driver_action_card.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_eta_panel.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_vehicle_info_card.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

/// Sheet content while the captain is heading to pickup.
class DriverOnWayView extends StatelessWidget {
  const DriverOnWayView({
    super.key,
    required this.progress,
    required this.riderPickupName,
    required this.riderBoarded,
    required this.fallbackArrival,
    required this.driverInitials,
    required this.driverName,
    required this.driverRatingLabel,
    required this.onCallDriver,
    required this.onChatDriver,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.vehicleName,
    required this.liveLocationLabel,
    this.vehicleSpeedKmh,
  });

  final RouteProgressSnapshot? progress;
  final String riderPickupName;
  final bool riderBoarded;
  final DateTime? fallbackArrival;
  final String driverInitials;
  final String driverName;
  final String driverRatingLabel;
  final VoidCallback onCallDriver;
  final VoidCallback onChatDriver;
  final String vehicleType;
  final String vehiclePlate;
  final String vehicleName;
  final String liveLocationLabel;
  final double? vehicleSpeedKmh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackingEtaPanel(
          progress: progress,
          riderPickupName: riderPickupName,
          riderBoarded: riderBoarded,
          fallbackArrival: fallbackArrival,
        ),
        const SizedBox(height: 16),
        TrackingDriverActionCard(
          driverInitials: driverInitials,
          driverName: driverName,
          driverRatingLabel: driverRatingLabel,
          onCallDriver: onCallDriver,
          onChatDriver: onChatDriver,
        ),
        const SizedBox(height: 16),
        TrackingVehicleInfoCard(
          vehicleType: vehicleType,
          vehiclePlate: vehiclePlate,
          vehicleName: vehicleName,
          liveLocationLabel: liveLocationLabel,
          vehicleSpeedKmh: vehicleSpeedKmh,
        ),
      ],
    );
  }
}
