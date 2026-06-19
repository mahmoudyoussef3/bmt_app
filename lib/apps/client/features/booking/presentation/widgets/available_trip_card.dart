import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

class AvailableTripCard extends StatelessWidget {
  const AvailableTripCard({
    super.key,
    required this.trip,
    required this.onBook,
  });

  final AvailableTripData trip;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final lowSeats = trip.availableSeats <= 4;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
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
                    Text(
                      trip.vehicleType,
                      style: ClientTypography.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vehicle ${trip.vehicleId}',
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              Text(
                trip.startingPrice,
                style: ClientTypography.priceMedium(
                  context,
                ).copyWith(color: ClientColors.primary, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: ClientColors.primaryLight,
                child: Text(
                  trip.driverName.isNotEmpty
                      ? trip.driverName.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: ClientColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.driverName,
                      style: ClientTypography.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Licensed captain',
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: lowSeats
                      ? ClientColors.journeyAmberLight
                      : ClientColors.journeyGreenLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  lowSeats ? '${trip.availableSeats} left' : 'Available',
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: lowSeats
                        ? ClientColors.onJourneyAmber
                        : ClientColors.onJourneyGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: ClientColors.borderFor(context)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Info(
                icon: Icons.schedule_rounded,
                label: 'ETA',
                value: trip.estimatedArrival,
              ),
              _Info(
                icon: Icons.route_rounded,
                label: 'Duration',
                value: trip.routeDuration,
              ),
              _Info(
                icon: Icons.event_seat_rounded,
                label: 'Seats',
                value: '${trip.availableSeats} available',
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClientButton(label: 'Book Now', expand: true, onPressed: onBook),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ClientColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textTertiaryFor(context)),
            ),
            Text(
              value,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
