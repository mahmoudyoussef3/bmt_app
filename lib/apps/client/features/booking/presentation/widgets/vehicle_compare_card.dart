import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_rating_row.dart';

/// Focused trip + vehicle choice card.
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
    return Material(
      color: selected
          ? ClientColors.primaryContainerFor(context)
          : ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? ClientColors.primary
                  : ClientColors.borderFor(context),
              width: selected ? 2 : 1,
            ),
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
                      color: ClientColors.primaryContainerFor(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: ClientColors.primaryFor(context),
                    ),
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
                          style: ClientTypography.headingSmall(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehicle.routeDuration,
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    vehicle.price,
                    style: ClientTypography.priceMedium(
                      context,
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
                  color: ClientColors.surfaceMutedFor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ClientColors.borderFor(context)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_bus_rounded,
                      color: ClientColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.headingSmall(context),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${vehicle.vehicleType} · ${vehicle.capacity} seats capacity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.bodySmall(context).copyWith(
                              color: ClientColors.textSecondaryFor(context),
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
              const SizedBox(height: 12),
              VehicleRatingRow(vehicle: vehicle),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onSelect,
                style: FilledButton.styleFrom(
                  backgroundColor: ClientColors.primary,
                  foregroundColor: ClientColors.textInverse,
                ),
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
        ),
      ),
    );
  }
}

class _OccupancyBlock extends StatelessWidget {
  const _OccupancyBlock({required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    final occupancyPercent = (vehicle.occupancyRatio * 100).round();
    final lowSeats = vehicle.availableSeats <= 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Occupancy',
                style: ClientTypography.labelMedium(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$occupancyPercent% full',
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: vehicle.occupancyRatio.clamp(0, 1),
            minHeight: 8,
            backgroundColor: ClientColors.surfaceMutedFor(context),
            valueColor: AlwaysStoppedAnimation<Color>(
              lowSeats ? ClientColors.journeyAmber : ClientColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${vehicle.availableSeats} available · ${vehicle.occupiedSeats} booked',
          style: ClientTypography.bodySmall(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
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
    final lowSeats = availableSeats <= 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: lowSeats
            ? ClientColors.journeyAmberLight
            : ClientColors.primaryContainerFor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$availableSeats seats',
        style: ClientTypography.labelMedium(context).copyWith(
          color: lowSeats
              ? ClientColors.onJourneyAmber
              : ClientColors.primaryFor(context),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
