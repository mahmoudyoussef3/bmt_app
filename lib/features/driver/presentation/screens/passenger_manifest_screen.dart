import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/domain/models/trip.dart';
import 'package:bmt_app/features/driver/domain/models/passenger.dart';
import 'package:bmt_app/features/driver/presentation/widgets/passenger_card.dart';
import 'package:bmt_app/features/driver/driver_service.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class PassengerManifestScreen extends StatefulWidget {
  final Trip trip;
  const PassengerManifestScreen({super.key, required this.trip});

  @override
  State<PassengerManifestScreen> createState() =>
      _PassengerManifestScreenState();
}

class _PassengerManifestScreenState extends State<PassengerManifestScreen> {
  String _query = '';
  PassengerStatus? _filter;

  List<Passenger> get _visible => widget.trip.passengers.where((p) {
    if (_query.isNotEmpty &&
        !p.name.toLowerCase().contains(_query.toLowerCase())) {
      return false;
    }
    if (_filter != null && p.status != _filter) {
      return false;
    }
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passenger Manifest')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search passenger by name',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                DropdownButton<PassengerStatus?>(
                  value: _filter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(
                      value: PassengerStatus.pending,
                      child: const Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: PassengerStatus.arrived,
                      child: const Text('Arrived'),
                    ),
                    DropdownMenuItem(
                      value: PassengerStatus.boarded,
                      child: const Text('Boarded'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filter = v),
                ),
                const SizedBox(width: 12),
                AppButton(label: 'Call All', outline: true, onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              itemCount: _visible.length,
              itemBuilder: (context, index) {
                final p = _visible[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PassengerCard(
                    passenger: p,
                    onMarkArrived: () =>
                        DriverService.cubitInstance.updatePassengerStatus(
                          widget.trip.id,
                          p.id,
                          PassengerStatus.arrived,
                        ),
                    onMarkBoarded: () =>
                        DriverService.cubitInstance.updatePassengerStatus(
                          widget.trip.id,
                          p.id,
                          PassengerStatus.boarded,
                        ),
                    onMarkSkipped: () =>
                        DriverService.cubitInstance.updatePassengerStatus(
                          widget.trip.id,
                          p.id,
                          PassengerStatus.skipped,
                        ),
                    onCall: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
