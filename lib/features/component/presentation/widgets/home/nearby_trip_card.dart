import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';

class NearbyTripCard extends StatelessWidget {
  const NearbyTripCard({super.key, required this.trip, required this.onTap});

  final NearbyTripData trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withAlpha(70),
                  scheme.secondary.withAlpha(40),
                ],
              ),
            ),
            child: Icon(
              Icons.directions_bus_filled_rounded,
              color: scheme.onSurface,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (trip.isLive) const StatusChip(label: 'Live'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: scheme.onSurface.withAlpha(160),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Departs ${trip.departureTime}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.event_seat_rounded,
                      size: 14,
                      color: scheme.onSurface.withAlpha(160),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.seatsLeft} seats',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurface.withAlpha(140),
          ),
        ],
      ),
    );
  }
}
