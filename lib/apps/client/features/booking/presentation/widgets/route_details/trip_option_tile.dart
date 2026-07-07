import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

/// A single selectable departure in Route Details' available-trips list.
class TripOptionTile extends StatelessWidget {
  const TripOptionTile({
    super.key,
    required this.trip,
    required this.selected,
    required this.onTap,
  });

  final RouteTripOptionData trip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withAlpha(18)
              : scheme.surfaceContainerHighest.withAlpha(45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline.withAlpha(45),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip.departureTime} - ${trip.arrivalTime}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip.vehicleType} · ${trip.availableSeats} seats',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(150),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              trip.price,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
