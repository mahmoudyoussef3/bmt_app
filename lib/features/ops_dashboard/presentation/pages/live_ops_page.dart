import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/status_chip.dart';
import '../cubit/live_ops_cubit.dart';
import '../cubit/live_ops_state.dart';
import '../../domain/models/trip_update.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/driver_position.dart';
import '../../domain/models/driver.dart';
import '../../domain/models/trip_event.dart';

Color _tripStatusColor(TripStatus status) {
  switch (status) {
    case TripStatus.scheduled:
      return Colors.blueGrey;
    case TripStatus.active:
      return Colors.blue;
    case TripStatus.completed:
      return Colors.green;
    case TripStatus.cancelled:
      return Colors.red;
    case TripStatus.delayed:
      return Colors.orange;
  }
}

Color _driverStatusColor(DriverStatus status) {
  switch (status) {
    case DriverStatus.online:
      return Colors.green;
    case DriverStatus.onTrip:
      return Colors.orange;
    case DriverStatus.offline:
      return Colors.grey;
    case DriverStatus.breakTime:
      return Colors.blueGrey;
  }
}

Color _eventSeverityColor(EventSeverity severity) {
  switch (severity) {
    case EventSeverity.info:
      return Colors.blue;
    case EventSeverity.warning:
      return Colors.orange;
    case EventSeverity.critical:
      return Colors.red;
  }
}

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
              final onTripDrivers = loaded.drivers
                  .where((d) => d.status == DriverStatus.onTrip)
                  .length;
              if (w < 900) {
                // stacked layout for narrow screens
                return Column(
                  children: [
                    _LiveOpsSummary(
                      trips: loaded.trips.length,
                      drivers: loaded.drivers.length,
                      busyDrivers: onTripDrivers,
                      events: loaded.events.length,
                    ),
                    const SizedBox(height: AppSpacing.small),
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

              // wide layout (responsive)
              final leftW = math.max(280, math.min(420, (w * 0.24))).toDouble();
              final rightW = math
                  .max(280, math.min(420, (w * 0.24)))
                  .toDouble();
              return Column(
                children: [
                  _LiveOpsSummary(
                    trips: loaded.trips.length,
                    drivers: loaded.drivers.length,
                    busyDrivers: onTripDrivers,
                    events: loaded.events.length,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Expanded(
                    child: Row(
                      children: [
                        // Left: active trips list
                        SizedBox(
                          width: leftW,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _TripList(trips: loaded.trips),
                          ),
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
                        SizedBox(
                          width: rightW,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _RightPanel(
                              events: loaded.events,
                              drivers: loaded.drivers,
                            ),
                          ),
                        ),
                      ],
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
    return _PanelCard(
      title: 'Active Trips',
      trailing: StatusChip(
        label: trips.length.toString(),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: trips.isEmpty
          ? const Center(child: Text('No active trips'))
          : ListView.separated(
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = trips[i];
                final progress = (t.progress).clamp(0.0, 1.0);
                final statusColor = _tripStatusColor(t.status);
                return Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: AppTokens.surfaceElevation,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.small),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.tripId,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            StatusChip(
                              label: t.status.name,
                              color: statusColor,
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                final cubit = context.read<LiveOpsCubit>();
                                if (v == 'cancel') {
                                  await cubit.cancelTrip(t.tripId);
                                }
                                if (v == 'complete') {
                                  await cubit.completeTrip(t.tripId);
                                }
                                if (v == 'reassign') {
                                  await cubit.reassignDriver(
                                    t.tripId,
                                    'DRIVER-1',
                                  );
                                }
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
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          'Progress ${(progress * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: statusColor,
                            backgroundColor: statusColor.withOpacity(0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.24),
            ),
          ),
          child: Stack(
            children: [
              // routes or background grid
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              Positioned(
                top: AppSpacing.small,
                left: AppSpacing.small,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                    vertical: AppSpacing.xSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: const Text(
                    'Live Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
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
                    color: _driverStatusColor(d.status),
                  ),
                ),
              Positioned(
                left: AppSpacing.small,
                bottom: AppSpacing.small,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.small),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _LegendItem(
                        color: Colors.blue,
                        label: 'Trip In Progress',
                      ),
                      _LegendItem(
                        color: Colors.orange,
                        label: 'Driver On Trip',
                      ),
                      _LegendItem(
                        color: Colors.green,
                        label: 'Driver Available',
                      ),
                    ],
                  ),
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
        Expanded(
          flex: 2,
          child: _PanelCard(
            title: 'Event Feed',
            trailing: StatusChip(
              label: events.length.toString(),
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: events.isEmpty
                ? const Center(child: Text('No events'))
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = events[i];
                      final color = _eventSeverityColor(e.severity);
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSmall,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.circle, size: 10, color: color),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.message,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: AppSpacing.xSmall),
                                  Text(
                                    '${e.type.name} • ${e.timestamp.toLocal()}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Expanded(
          child: _PanelCard(
            title: 'Drivers',
            trailing: StatusChip(
              label: drivers.length.toString(),
              color: Theme.of(context).colorScheme.tertiary,
            ),
            child: drivers.isEmpty
                ? const Center(child: Text('No drivers'))
                : ListView.separated(
                    itemCount: drivers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final d = drivers[i];
                      final color = _driverStatusColor(d.status);
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSmall,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_pin_circle, color: color),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.driverId,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: AppSpacing.xSmall),
                                  Text(
                                    'Lat ${d.position.lat.toStringAsFixed(3)} • Lng ${d.position.lng.toStringAsFixed(3)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(label: d.status.name, color: color),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _LiveOpsSummary extends StatelessWidget {
  final int trips;
  final int drivers;
  final int busyDrivers;
  final int events;

  const _LiveOpsSummary({
    required this.trips,
    required this.drivers,
    required this.busyDrivers,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTokens.surfaceElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            _pill(context, 'Active Trips', trips.toString(), Colors.blue),
            _pill(context, 'Drivers', drivers.toString(), Colors.teal),
            _pill(context, 'On Trip', busyDrivers.toString(), Colors.orange),
            _pill(context, 'Events', events.toString(), Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xSmall),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _PanelCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: AppTokens.surfaceElevation,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
