import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/live_ops_cubit.dart';
import '../cubit/live_ops_state.dart';
import '../../domain/models/trip_update.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/driver_position.dart';
import '../../domain/models/driver.dart';
import '../../domain/models/trip_event.dart';

class LiveOpsPage extends StatelessWidget {
  const LiveOpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Operations')),
      body: BlocBuilder<LiveOpsCubit, LiveOpsState>(
        builder: (context, state) {
          if (state is LiveOpsLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is LiveOpsError)
            return Center(child: Text('Error: ${state.message}'));
          final loaded = state as LiveOpsLoaded;
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              if (w < 900) {
                // stacked layout for narrow screens
                return Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: _TripList(trips: loaded.trips),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _MapView(
                        trips: loaded.trips,
                        drivers: loaded.drivers,
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 200,
                      child: _RightPanel(
                        events: loaded.events,
                        drivers: loaded.drivers,
                      ),
                    ),
                  ],
                );
              }

              // wide layout (original)
              return Row(
                children: [
                  // Left: active trips list
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(8),
                    child: _TripList(trips: loaded.trips),
                  ),
                  const VerticalDivider(width: 1),
                  // Center: mock map
                  Expanded(
                    child: _MapView(
                      trips: loaded.trips,
                      drivers: loaded.drivers,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Right: events + drivers
                  Container(
                    width: 340,
                    padding: const EdgeInsets.all(8),
                    child: _RightPanel(
                      events: loaded.events,
                      drivers: loaded.drivers,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  final List<TripUpdate> trips;
  const _TripList({required this.trips});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Active Trips',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: trips.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = trips[i];
              return ListTile(
                title: Text(t.tripId),
                subtitle: Text(
                  'Status: ${t.status.name} • ${(t.progress * 100).toStringAsFixed(0)}%',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    final cubit = context.read<LiveOpsCubit>();
                    if (v == 'cancel') await cubit.cancelTrip(t.tripId);
                    if (v == 'complete') await cubit.completeTrip(t.tripId);
                    if (v == 'reassign')
                      await cubit.reassignDriver(t.tripId, 'DRIVER-1');
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('Cancel Trip'),
                    ),
                    const PopupMenuItem(
                      value: 'complete',
                      child: Text('Mark Completed'),
                    ),
                    const PopupMenuItem(
                      value: 'reassign',
                      child: Text('Reassign Driver'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MapView extends StatelessWidget {
  final List<TripUpdate> trips;
  final List<DriverPosition> drivers;
  const _MapView({required this.trips, required this.drivers});

  @override
  Widget build(BuildContext context) {
    // Simple mock map: a box with moving markers based on normalized positions
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Container(
          color: Colors.grey.shade100,
          child: Stack(
            children: [
              // routes or background grid
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              // trip markers
              for (var t in trips)
                if (t.location != null)
                  Positioned(
                    left: (t.location!.lng * w).clamp(0.0, w - 24),
                    top: (t.location!.lat * h).clamp(0.0, h - 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: t.status == TripStatus.cancelled
                              ? Colors.red
                              : (t.status == TripStatus.completed
                                    ? Colors.grey
                                    : Colors.blue),
                        ),
                        Text(t.tripId, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
              // driver markers
              for (var d in drivers)
                Positioned(
                  left: (d.position.lng * w).clamp(0.0, w - 24),
                  top: (d.position.lat * h).clamp(0.0, h - 24),
                  child: Icon(
                    Icons.person_pin_circle,
                    color: d.status == DriverStatus.onTrip
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    for (var x = 0; x < size.width; x += 40)
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x.toDouble(), size.height),
        paint,
      );
    for (var y = 0; y < size.height; y += 40)
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(size.width, y.toDouble()),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RightPanel extends StatelessWidget {
  final List<TripEvent> events;
  final List<DriverPosition> drivers;
  const _RightPanel({required this.events, required this.drivers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Event Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[i];
              return ListTile(
                leading: Icon(
                  e.severity == EventSeverity.critical
                      ? Icons.warning
                      : Icons.event,
                  color: e.severity == EventSeverity.critical
                      ? Colors.red
                      : Colors.orange,
                ),
                title: Text(e.message),
                subtitle: Text('${e.type.name} • ${e.timestamp.toLocal()}'),
              );
            },
          ),
        ),
        const Divider(),
        const Text('Drivers', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, i) {
              final d = drivers[i];
              return ListTile(
                leading: Icon(
                  Icons.person,
                  color: d.status == DriverStatus.onTrip
                      ? Colors.orange
                      : Colors.green,
                ),
                title: Text(d.driverId),
                subtitle: Text(
                  'Lat:${d.position.lat.toStringAsFixed(3)} Lng:${d.position.lng.toStringAsFixed(3)}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
