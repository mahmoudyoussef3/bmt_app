import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
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
    final scheme = Theme.of(context).colorScheme;
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
                  color: scheme.primary.withAlpha(36),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.directions_bus_filled_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.vehicleType,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vehicle ${trip.vehicleId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                trip.startingPrice,
                style: AppTextThemes.priceEmphasis(
                  scheme,
                ).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const AppAvatar(initials: 'AM', radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.driverName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Licensed captain',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: lowSeats ? '${trip.availableSeats} left' : 'Available',
              ),
            ],
          ),
          const SizedBox(height: 14),
          const AppSeparator(),
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
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Select Vehicle',
              height: 46,
              onPressed: onBook,
            ),
          ),
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
