import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/assigned_trip.dart';

class AssignedTripCard extends StatelessWidget {
  const AssignedTripCard({
    super.key,
    required this.trip,
    required this.onOpen,
    required this.onManifest,
  });

  final AssignedTrip trip;
  final VoidCallback onOpen;
  final VoidCallback onManifest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.route,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(label: _statusLabel(trip.status)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'المركبة ${trip.vehicleNumber} • ${trip.plateNumber}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                _timeRange(trip),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 14),
              Icon(Icons.people_alt_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                '${trip.boardedCount}/${trip.passengerCount} صعد',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(label: 'فتح الرحلة', onPressed: onOpen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'الركاب',
                  outline: true,
                  onPressed: onManifest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeRange(AssignedTrip trip) {
    return '${_time(trip.departureTime)} - ${_time(trip.expectedArrivalTime)}';
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _statusLabel(AssignedTripStatus status) {
    return switch (status) {
      AssignedTripStatus.scheduled => 'مجدولة',
      AssignedTripStatus.boarding => 'صعود الركاب',
      AssignedTripStatus.inProgress => 'جارية',
      AssignedTripStatus.completed => 'مكتملة',
    };
  }
}
