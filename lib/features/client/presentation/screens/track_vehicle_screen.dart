import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/features/client/presentation/cubits/tracking_cubit.dart';
import 'package:bmt_app/core/theme/app_theme.dart';

class TrackVehicleScreen extends StatelessWidget {
  const TrackVehicleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackingCubit, TrackingState>(
      builder: (context, state) {
        if (state.trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Track Vehicle')),
            body: const Center(child: Text('No active trip to track')),
          );
        }

        final eta = state.eta;
        final minutesLeft = eta?.difference(DateTime.now()).inMinutes ?? 0;

        return Scaffold(
          appBar: AppBar(title: const Text('Track Vehicle')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map Placeholder
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${state.trip!.pickupLocation.name} → ${state.trip!.dropoffLocation.name}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        // Vehicle marker
                        Positioned(
                          top: 80,
                          left: 40,
                          child: Column(
                            children: [
                              const Text('🚌', style: TextStyle(fontSize: 32)),
                              const SizedBox(height: 4),
                              Text(
                                state.trip!.vehicle.number,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ETA Card
                  Card(
                    color: AppTheme.primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ETA',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatTime(state.eta!)}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Arriving in',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                minutesLeft > 0
                                    ? '$minutesLeft min'
                                    : 'Arriving soon',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Trip Details
                  Text(
                    'Trip Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(
                            icon: '🚗',
                            label: 'Vehicle',
                            value: state.trip!.vehicle.number,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: '👨‍✈️',
                            label: 'Driver',
                            value: state.driverName ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: '📞',
                            label: 'Driver Phone',
                            value: state.driverPhone ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: '📍',
                            label: 'Pickup',
                            value: state.trip!.pickupLocation.name,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: '🎯',
                            label: 'Dropoff',
                            value: state.trip!.dropoffLocation.name,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: '⏰',
                            label: 'Departure',
                            value: _formatTime(state.trip!.departureTime),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Driver Contact Card
                  Card(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Driver',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Would open phone dial
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Calling ${state.driverPhone}',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.call),
                                  label: const Text('Call'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Would open WhatsApp
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Opening WhatsApp...'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.message),
                                  label: const Text('WhatsApp'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
