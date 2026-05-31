import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/domain/models/trip.dart';
import 'package:bmt_app/features/driver/domain/models/passenger.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class TripCompletionScreen extends StatelessWidget {
  final Trip trip;
  const TripCompletionScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final total = trip.passengers.length;
    final boarded = trip.passengers
        .where((p) => p.status == PassengerStatus.boarded)
        .length;
    final absent = total - boarded;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Completion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Summary',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Passengers: $total',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Boarded: $boarded',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Absent: $absent',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppButton(label: 'Submit Report', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
