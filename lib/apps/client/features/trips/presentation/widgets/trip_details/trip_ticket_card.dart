import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_premium_panel.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_qr_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';

/// The boarding-ticket QR card shown for upcoming/in-progress trips.
class TripTicketCard extends StatelessWidget {
  const TripTicketCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return TripPremiumPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const TripSoftIcon(
                icon: Icons.qr_code_2_rounded,
                color: ClientColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Boarding Ticket',
                  style: ClientTypography.headingSmall(context),
                ),
              ),
              const TripInlineBadge(
                label: 'Ready',
                color: ClientColors.journeyGreen,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TripQrCard(reference: trip.reference),
        ],
      ),
    );
  }
}
