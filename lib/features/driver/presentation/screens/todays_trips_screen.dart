import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/driver_service.dart';
import 'package:bmt_app/features/driver/presentation/widgets/trip_card.dart';

class TodaysTripsScreen extends StatefulWidget {
  const TodaysTripsScreen({super.key});

  @override
  State<TodaysTripsScreen> createState() => _TodaysTripsScreenState();
}

class _TodaysTripsScreenState extends State<TodaysTripsScreen> {
  @override
  void initState() {
    super.initState();
    DriverService.cubitInstance.addListener(_onChange);
  }

  @override
  void dispose() {
    DriverService.cubitInstance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final trips = DriverService.cubitInstance.trips;

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Trips")),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return Column(
            children: [
              TripCard(
                trip: trip,
                onView: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TripCard.fullTripDetails(trip),
                  ),
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
