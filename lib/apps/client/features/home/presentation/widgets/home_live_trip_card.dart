import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_journey_endpoints.dart';

/// The passenger's current journey, pinned near the top of home.
/// Active trips get a live pulse and a tracking CTA; upcoming trips get
/// schedule context and a details CTA.
class HomeLiveTripCard extends StatelessWidget {
  const HomeLiveTripCard({super.key, required this.trip, required this.onTap});

  final HomeCurrentTripData trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive(trip.statusLabel);
    final statusColor = isActive
        ? ClientColors.journeyGreen
        : ClientColors.primaryFor(context);

    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ClientSpacing.lg),
      borderColor: statusColor.withAlpha(60),
      useShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Trip in progress' : 'Upcoming trip',
                      style: ClientTypography.labelLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      trip.schedule,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ClientStatusBadge(
                status: isActive
                    ? ClientJourneyStatus.active
                    : ClientJourneyStatus.upcoming,
                label: trip.statusLabel,
                showDot: isActive,
              ),
            ],
          ),
          const SizedBox(height: 20),
          HomeJourneyEndpoints(
            pickup: trip.pickup,
            destination: trip.destination,
          ),
          if (trip.driverLine?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ClientColors.surfaceMutedFor(context),
                borderRadius: BorderRadius.circular(ClientRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: ClientColors.textSecondaryFor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.driverLine!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          ClientButton(
            label: isActive ? 'Track your bus' : 'View trip details',
            icon: Icon(
              isActive ? Icons.near_me_rounded : Icons.receipt_long_rounded,
              color: Colors.white,
              size: 19,
            ),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  static bool _isActive(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('active') ||
        normalized.contains('progress') ||
        normalized.contains('boarding');
  }
}
