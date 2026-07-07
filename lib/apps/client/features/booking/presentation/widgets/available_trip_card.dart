import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/widgets.dart';
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

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.vehicleType,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vehicle ${trip.vehicleId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(170),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                trip.startingPrice,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(18),
                child: Text(
                  trip.driverName.isNotEmpty
                      ? trip.driverName.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w800,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Licensed captain',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(170),
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: lowSeats ? '${trip.availableSeats} left' : 'Available',
                color: lowSeats
                    ? Theme.of(context).colorScheme.tertiary.withAlpha(24)
                    : Theme.of(context).colorScheme.secondary.withAlpha(20),
                textColor: lowSeats
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Theme.of(context).colorScheme.outline),
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
          AppButton.primary(text: 'Book Now', onPressed: onBook),
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
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
              ),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}
