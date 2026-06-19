import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

class NearbyTripCard extends StatelessWidget {
  const NearbyTripCard({super.key, required this.trip, required this.onTap});

  final NearbyTripData trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      ClientColors.primaryLight,
                      ClientColors.primaryMuted,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: ClientColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${trip.pickup} → ${trip.destination}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.bodyMedium(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (trip.isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ClientColors.journeyGreenLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Live',
                              style: ClientTypography.labelSmall(context)
                                  .copyWith(
                                    color: ClientColors.onJourneyGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: ClientColors.textSecondaryFor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Departs ${trip.departureTime}',
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.event_seat_rounded,
                          size: 14,
                          color: ClientColors.textSecondaryFor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.seatsLeft} seats',
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ClientColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
