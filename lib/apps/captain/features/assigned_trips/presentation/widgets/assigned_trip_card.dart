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
    final progress = trip.passengerCount == 0
        ? 0.0
        : trip.boardedCount / trip.passengerCount;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.route,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              StatusChip(
                label: _statusLabel(trip.status),
                color: _statusColor(trip.status).withAlpha(28),
                textColor: _statusColor(trip.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.directions_bus_rounded,
                label: trip.vehicleNumber.isEmpty
                    ? 'مركبة غير محددة'
                    : trip.vehicleNumber,
              ),
              _InfoPill(
                icon: Icons.confirmation_number_rounded,
                label: trip.plateNumber.isEmpty
                    ? 'لوحة غير محددة'
                    : trip.plateNumber,
              ),
              _InfoPill(icon: Icons.schedule_rounded, label: _timeRange(trip)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.boardedCount}/${trip.passengerCount} صعد',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(progress: progress),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'فتح الرحلة',
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  onPressed: onOpen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'الركاب',
                  icon: const Icon(Icons.people_alt_rounded, size: 18),
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

  Color _statusColor(AssignedTripStatus status) {
    return switch (status) {
      AssignedTripStatus.scheduled => Colors.blue,
      AssignedTripStatus.boarding => Colors.orange,
      AssignedTripStatus.inProgress => Colors.green,
      AssignedTripStatus.completed => Colors.grey,
    };
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
