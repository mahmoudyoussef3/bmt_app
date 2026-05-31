import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/domain/models/trip.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/driver/presentation/screens/passenger_manifest_screen.dart';
import 'package:bmt_app/features/driver/driver_service.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.route,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vehicle: ${trip.vehicle.number} • Plate: ${trip.vehicle.plate}',
                ),
                const SizedBox(height: 8),
                Text('Capacity: ${trip.vehicle.capacity}'),
                const SizedBox(height: 8),
                Text('Departure: ${trip.departure}'),
                const SizedBox(height: 8),
                Text('Expected Arrival: ${trip.expectedArrival}'),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Open Passenger List',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PassengerManifestScreen(trip: trip),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Start Trip',
                  outline: true,
                  onPressed: () =>
                      DriverService.cubitInstance.startTrip(trip.id),
                ),
                const SizedBox(height: 8),
                AppButton(label: 'Open Navigation', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
