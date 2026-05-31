import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/domain/models/trip.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class PickupManagementScreen extends StatelessWidget {
  final Trip trip;
  const PickupManagementScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Management')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        itemCount: trip.stops.length,
        itemBuilder: (context, index) {
          final stop = trip.stops[index];
          final passengersForStop = trip.passengers
              .where((p) => p.pickupPoint == stop)
              .length;
          return Column(
            children: [
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ETA: --:--',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(170),
                              ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '$passengersForStop passengers',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Mark Stop Reached',
                          outline: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}
