import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_driver_action_card.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_eta_panel.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

/// Sheet content once boarding has opened at the pickup stop.
class BoardingView extends StatelessWidget {
  const BoardingView({
    super.key,
    required this.progress,
    required this.riderPickupName,
    required this.riderBoarded,
    required this.fallbackArrival,
    required this.bookingLabel,
    required this.driverInitials,
    required this.driverName,
    required this.driverRatingLabel,
    required this.onCallDriver,
    required this.onChatDriver,
  });

  final RouteProgressSnapshot? progress;
  final String riderPickupName;
  final bool riderBoarded;
  final DateTime? fallbackArrival;
  final String bookingLabel;
  final String driverInitials;
  final String driverName;
  final String driverRatingLabel;
  final VoidCallback onCallDriver;
  final VoidCallback onChatDriver;

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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ClientColors.primary.withAlpha(50)),
          ),
          child: Column(
            children: [
              const Text(
                'Boarding is open for this confirmed booking',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bookingLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: ClientColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TrackingDriverActionCard(
          driverInitials: driverInitials,
          driverName: driverName,
          driverRatingLabel: driverRatingLabel,
          onCallDriver: onCallDriver,
          onChatDriver: onChatDriver,
        ),
      ],
    );
  }
}
