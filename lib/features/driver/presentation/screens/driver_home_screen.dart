import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/driver_service.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/driver/presentation/widgets/kpi_card.dart';
import 'package:bmt_app/features/driver/domain/models/passenger.dart';
import 'package:bmt_app/features/driver/presentation/widgets/trip_card.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
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
    final cubit = DriverService.cubitInstance;
    final trips = cubit.trips;
    final upcoming = trips.isNotEmpty ? trips.first : null;
    final activePassengers = trips.fold<int>(
      0,
      (p, t) =>
          p +
          t.passengers
              .where(
                (p) =>
                    p.status == PassengerStatus.pending ||
                    p.status == PassengerStatus.arrived,
              )
              .length,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmed Mohamed',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Vehicle: MT-2847 • Plate: ABC-1234',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Active passengers: $activePassengers',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AppAvatar(initials: 'AM'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: KpiCard(label: 'Trips', value: '${trips.length}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KpiCard(
                    label: 'Boarded',
                    value:
                        '${trips.fold<int>(0, (p, t) => p + t.passengers.where((p) => p.status == PassengerStatus.boarded).length)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KpiCard(
                    label: 'Pending',
                    value:
                        '${trips.fold<int>(0, (p, t) => p + t.passengers.where((p) => p.status == PassengerStatus.pending).length)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Start Trip',
                          onPressed: () {
                            if (upcoming != null) {
                              cubit.startTrip(upcoming.id);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: 'View Passengers',
                          outline: true,
                          onPressed: () {
                            if (upcoming != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TripCard.fullTripDetails(upcoming),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Today\'s Trips',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 10),
            for (final trip in trips) ...[
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
          ],
        ),
      ),
    );
  }
}
