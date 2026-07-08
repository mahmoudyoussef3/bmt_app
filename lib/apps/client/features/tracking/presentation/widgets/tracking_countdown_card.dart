import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_misc_widgets.dart';

/// Pre-trip hero card: countdown to departure plus a live-location strip.
class TrackingCountdownCard extends StatelessWidget {
  const TrackingCountdownCard({
    super.key,
    required this.relativeDeparture,
    required this.departureTimeLabel,
    required this.hasLiveVehicleLocation,
    required this.liveLocationLabel,
  });

  final String relativeDeparture;
  final String departureTimeLabel;
  final bool hasLiveVehicleLocation;
  final String liveLocationLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ClientColors.primary.withAlpha(45),
            ClientColors.journeyGreen.withAlpha(25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ClientColors.primary.withAlpha(90),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withAlpha(30),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TrackingPulseIndicator(color: ClientColors.primary),
              const SizedBox(width: 8),
              Text(
                'UPCOMING RIDE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: ClientColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            relativeDeparture,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scheduled departure at $departureTimeLabel',
            style: TextStyle(
              fontSize: 13,
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context).withAlpha(180),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 16,
                  color: ClientColors.journeyGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  hasLiveVehicleLocation
                      ? liveLocationLabel
                      : 'Waiting for the captain to send a location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.journeyGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
