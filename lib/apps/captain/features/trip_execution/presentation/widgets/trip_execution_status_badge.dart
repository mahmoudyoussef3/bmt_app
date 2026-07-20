import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/widgets/captain_status_chip.dart';

import '../../domain/entities/trip_execution_state.dart';

/// The trip's lifecycle status as a chip.
class TripExecutionStatusBadge extends StatelessWidget {
  const TripExecutionStatusBadge({super.key, required this.status});

  final TripExecutionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, variant, icon) = switch (status) {
      TripExecutionStatus.scheduled => (
        'لم تُفتح',
        CaptainStatusVariant.neutral,
        Icons.lock_clock_rounded,
      ),
      TripExecutionStatus.openForBooking => (
        'الحجز مفتوح',
        CaptainStatusVariant.info,
        Icons.event_available_rounded,
      ),
      TripExecutionStatus.boarding => (
        'صعود',
        CaptainStatusVariant.warning,
        Icons.people_rounded,
      ),
      TripExecutionStatus.inProgress => (
        'جارية',
        CaptainStatusVariant.success,
        Icons.electric_car_rounded,
      ),
      TripExecutionStatus.completed => (
        'مكتملة',
        CaptainStatusVariant.neutral,
        Icons.check_circle_rounded,
      ),
      TripExecutionStatus.cancelled => (
        'ملغاة',
        CaptainStatusVariant.error,
        Icons.cancel_rounded,
      ),
    };

    return CaptainStatusChip(label: label, variant: variant, icon: icon);
  }
}
