import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/domain/models/trip.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onView;

  const TripCard({super.key, required this.trip, this.onView});

  static Widget fullTripDetails(Trip trip) {
    return Scaffold(
      appBar: AppBar(title: Text('Trip Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.route,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Departure: ${trip.departure}'),
            const SizedBox(height: 4),
            Text('Expected Arrival: ${trip.expectedArrival}'),
            const SizedBox(height: 12),
            Text(
              'Vehicle: ${trip.vehicle.number} • Plate: ${trip.vehicle.plate}',
            ),
            const SizedBox(height: 12),
            Text('Passengers: ${trip.passengers.length}'),
            const SizedBox(height: 16),
            AppButton(label: 'Open Passenger List', onPressed: () {}),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.route,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Departure: ${_timeString(trip.departure)} • ETA: ${_timeString(trip.expectedArrival)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(170),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Passengers: ${trip.passengers.length} • Vehicle: ${trip.vehicle.number}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(onPressed: onView, child: const Text('Details')),
            ],
          ),
        ],
      ),
    );
  }

  String _timeString(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
