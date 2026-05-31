import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/domain/models/passenger.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class PassengerCard extends StatelessWidget {
  final Passenger passenger;
  final VoidCallback? onMarkArrived;
  final VoidCallback? onMarkBoarded;
  final VoidCallback? onMarkSkipped;
  final VoidCallback? onCall;

  const PassengerCard({
    super.key,
    required this.passenger,
    this.onMarkArrived,
    this.onMarkBoarded,
    this.onMarkSkipped,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Seat ${passenger.seat} • ${passenger.pickupPoint} → ${passenger.destination}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pickup: ${passenger.pickupTime} • ${passenger.phone}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onCall,
                icon: Icon(Icons.call, color: scheme.primary),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'arrived') onMarkArrived?.call();
                  if (v == 'boarded') onMarkBoarded?.call();
                  if (v == 'skipped') onMarkSkipped?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'arrived',
                    child: Text('Mark Arrived'),
                  ),
                  const PopupMenuItem(
                    value: 'boarded',
                    child: Text('Mark Boarded'),
                  ),
                  const PopupMenuItem(
                    value: 'skipped',
                    child: Text('Mark Skipped'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
