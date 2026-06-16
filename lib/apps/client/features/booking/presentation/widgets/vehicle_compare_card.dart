import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Focused trip + vehicle choice card.
///
/// This screen is about choosing a departure and the assigned vehicle quickly,
/// so non-decision details such as driver profile, image gallery, and rating are
/// intentionally omitted.
class VehicleCompareCard extends StatelessWidget {
  const VehicleCompareCard({
    super.key,
    required this.vehicle,
    required this.onSelect,
    this.selected = false,
  });

  final VehicleDetailData vehicle;
  final VoidCallback onSelect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      radius: 18,
      padding: const EdgeInsets.all(16),
      onTap: onSelect,
      border: Border.all(
        color: selected ? scheme.primary : scheme.outline.withAlpha(70),
        width: selected ? 1.4 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.schedule_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.departureTime} - ${vehicle.estimatedArrival}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.routeDuration,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(145),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                vehicle.price,
                style: AppTextThemes.priceEmphasis(
                  scheme,
                ).copyWith(fontSize: 17, height: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _OccupancyBlock(vehicle: vehicle),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outline.withAlpha(45)),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_bus_rounded, color: scheme.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${vehicle.vehicleType} · ${vehicle.capacity} seats capacity',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SeatsBadge(availableSeats: vehicle.availableSeats),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onSelect,
            icon: Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_rounded,
              size: 19,
            ),
            label: Text(selected ? 'Selected' : 'Select trip and vehicle'),
          ),
        ],
      ),
    );
  }
}

class _OccupancyBlock extends StatelessWidget {
  const _OccupancyBlock({required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final occupancyPercent = (vehicle.occupancyRatio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Occupancy',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(145),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$occupancyPercent% full',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: vehicle.occupancyRatio.clamp(0, 1),
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              vehicle.availableSeats <= 4 ? scheme.tertiary : scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${vehicle.availableSeats} available · ${vehicle.occupiedSeats} booked',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withAlpha(150),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SeatsBadge extends StatelessWidget {
  const _SeatsBadge({required this.availableSeats});

  final int availableSeats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lowSeats = availableSeats <= 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: (lowSeats ? scheme.tertiary : scheme.primary).withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$availableSeats seats',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: lowSeats ? scheme.tertiary : scheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
