import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/features/driver/presentation/cubits/driver_trip_cubit.dart';
import 'package:bmt_app/shared/models/models.dart';
import 'package:bmt_app/core/theme/app_theme.dart';

class DriverTripListScreen extends StatelessWidget {
  const DriverTripListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver - Trip List'),
        centerTitle: true,
      ),
      body: BlocBuilder<DriverTripCubit, DriverTripState>(
        builder: (context, state) {
          if (state.assignedTrips.isEmpty) {
            return const Center(child: Text('No assigned trips today'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.assignedTrips.length,
            itemBuilder: (context, index) {
              final trip = state.assignedTrips[index];
              return _TripListItem(
                trip: trip,
                onArrived: () {
                  context.read<DriverTripCubit>().markArrived(trip.id);
                },
                onBoarded: () {
                  context.read<DriverTripCubit>().markBoarded(trip.id);
                },
                onSkipped: () {
                  context.read<DriverTripCubit>().skipPassenger(trip.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TripListItem extends StatelessWidget {
  final Trip trip;
  final VoidCallback onArrived;
  final VoidCallback onBoarded;
  final VoidCallback onSkipped;

  const _TripListItem({
    required this.trip,
    required this.onArrived,
    required this.onBoarded,
    required this.onSkipped,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(trip.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip: ${trip.vehicle.number}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTime(trip.departureTime)} - ${_formatTime(trip.estimatedArrival)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trip.status.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route info
            _RouteInfo(
              pickup: trip.pickupLocation.name,
              dropoff: trip.dropoffLocation.name,
            ),
            const SizedBox(height: 16),

            // Passenger list
            Text(
              'Passengers (${trip.vehicle.occupancy})',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(trip.vehicle.occupancy, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PassengerItem(
                  passengerNumber: index + 1,
                  onBoarded: onBoarded,
                  onSkipped: onSkipped,
                ),
              );
            }),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: trip.status == TripStatus.inProgress
                        ? null
                        : onArrived,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Arrived'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
        return AppTheme.primaryColor;
      case TripStatus.inProgress:
        return AppTheme.secondaryColor;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
        return AppTheme.accentColor;
    }
  }
}

class _RouteInfo extends StatelessWidget {
  final String pickup;
  final String dropoff;

  const _RouteInfo({required this.pickup, required this.dropoff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pickup,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dropoff,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassengerItem extends StatefulWidget {
  final int passengerNumber;
  final VoidCallback onBoarded;
  final VoidCallback onSkipped;

  const _PassengerItem({
    required this.passengerNumber,
    required this.onBoarded,
    required this.onSkipped,
  });

  @override
  State<_PassengerItem> createState() => _PassengerItemState();
}

class _PassengerItemState extends State<_PassengerItem> {
  late String _status; // pending, boarded, skipped

  @override
  void initState() {
    super.initState();
    _status = 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor,
            foregroundColor: Colors.white,
            child: Text('P${widget.passengerNumber}'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passenger ${widget.passengerNumber}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _status.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_status == 'pending')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => _status = 'boarded');
                    widget.onBoarded();
                  },
                  icon: const Icon(Icons.check_circle),
                  color: AppTheme.secondaryColor,
                  tooltip: 'Boarded',
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _status = 'skipped');
                    widget.onSkipped();
                  },
                  icon: const Icon(Icons.cancel),
                  color: AppTheme.accentColor,
                  tooltip: 'Skipped',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'pending':
        return AppTheme.primaryColor;
      case 'boarded':
        return AppTheme.secondaryColor;
      case 'skipped':
        return AppTheme.accentColor;
      default:
        return Colors.grey;
    }
  }
}
