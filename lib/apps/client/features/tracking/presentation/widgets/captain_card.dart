import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/tracking/vehicle_sample.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/maps/overlays/glass_info_card.dart';

import '../../domain/entities/tracking_trip.dart';

/// Floating identity card for the live map: who's driving, what they're
/// driving, and the live GPS/speed status behind the vehicle marker. The
/// live-tracking analog of the booking map's route info panel — same
/// [GlassInfoCard] shell, trip-specific content instead of route facts.
class CaptainCard extends StatelessWidget {
  const CaptainCard({
    super.key,
    required this.driverInitials,
    required this.driverName,
    required this.vehiclePlate,
    required this.currentState,
    this.driverRating,
    this.sample,
  });

  final String driverInitials;
  final String driverName;
  final String vehiclePlate;
  final TrackingTripState currentState;
  final double? driverRating;
  final VehicleSample? sample;

  @override
  Widget build(BuildContext context) {
    final (icon, tone, label) = _status(context);
    final mutedStyle = MapStyle.pillLabel(
      context,
    ).copyWith(fontSize: 11, color: MapStyle.onSurfaceMuted(context));

    return GlassInfoCard(
      maxWidth: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ClientColors.primaryLight,
                child: Text(
                  driverInitials,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: ClientColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      driverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MapStyle.pillLabel(context).copyWith(fontSize: 13),
                    ),
                    Row(
                      children: [
                        if ((driverRating ?? 0) > 0) ...[
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: 2),
                          Text(driverRating!.toStringAsFixed(1), style: mutedStyle),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            vehiclePlate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: mutedStyle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 14, color: tone),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(color: MapStyle.onSurface(context)),
                ),
              ),
              if (sample != null && sample!.isMoving && !sample!.isStale)
                Text(
                  '${sample!.speedKmh.round()} km/h',
                  style: mutedStyle.copyWith(color: ClientColors.journeyGreen),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _status(BuildContext context) {
    final muted = MapStyle.onSurfaceMuted(context);
    if (currentState == TrackingTripState.completed) {
      return (Icons.flag_rounded, ClientColors.journeyGreen, 'Trip completed');
    }
    final current = sample;
    if (current == null) {
      return (Icons.location_searching_rounded, muted, 'Waiting for location');
    }
    final age = DateTime.now().difference(current.fixRecordedAt);
    final ago = age.inMinutes < 1 ? 'just now' : '${age.inMinutes} min ago';
    if (current.isStale) {
      return (
        Icons.gps_off_rounded,
        Theme.of(context).colorScheme.error,
        'Signal lost — $ago',
      );
    }
    return (Icons.my_location_rounded, ClientColors.journeyGreen, 'Live — $ago');
  }
}
