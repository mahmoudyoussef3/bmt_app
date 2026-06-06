import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class VehicleCard extends StatelessWidget {
  final String id;
  final String driver;
  final String time;
  final int seatsLeft;
  final double occupancy;
  final VoidCallback onBook;

  const VehicleCard({
    super.key,
    required this.id,
    required this.driver,
    required this.time,
    required this.seatsLeft,
    required this.occupancy,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(14),
      color: scheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle $id',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    driver,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(160),
                    ),
                  ),
                ],
              ),
              StatusChip(label: seatsLeft > 0 ? 'Available' : 'Full'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(time, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 14),
              Icon(Icons.event_seat_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                '$seatsLeft seats left',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Occupancy',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  AppProgressBar(progress: occupancy),
                ],
              ),
              ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Select Seat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
