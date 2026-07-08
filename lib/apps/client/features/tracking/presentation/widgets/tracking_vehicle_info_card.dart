import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_feature_badge.dart';

/// Assigned vehicle summary: type badge, plate, and live-location/speed
/// feature badges. Used both in the pre-trip list and the "driver on the
/// way" sheet.
class TrackingVehicleInfoCard extends StatelessWidget {
  const TrackingVehicleInfoCard({
    super.key,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.vehicleName,
    required this.liveLocationLabel,
    this.vehicleSpeedKmh,
  });

  final String vehicleType;
  final String vehiclePlate;
  final String vehicleName;
  final String liveLocationLabel;
  final double? vehicleSpeedKmh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  vehicleType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ClientColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClientColors.borderFor(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vehiclePlate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            vehicleName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TrackingFeatureBadge(
                icon: Icons.location_searching_rounded,
                label: liveLocationLabel,
              ),
              const SizedBox(width: 8),
              if (vehicleSpeedKmh != null)
                TrackingFeatureBadge(
                  icon: Icons.speed_rounded,
                  label: '${vehicleSpeedKmh!.round()} km/h',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

