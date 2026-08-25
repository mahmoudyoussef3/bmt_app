import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_status_chip.dart';

import '../../domain/entities/assigned_trip.dart';

/// The status word a trip carries wherever it appears.
///
/// Lives apart from [TripStatusBadge] because the focus card's gradient crown
/// states the same status as plain white text rather than as a chip — one
/// wording, two presentations.
String assignedTripStatusLabel(AssignedTripStatus status) => switch (status) {
  AssignedTripStatus.scheduled => 'لم تُفتح',
  AssignedTripStatus.openForBooking => 'الحجز مفتوح',
  AssignedTripStatus.boarding => 'صعود',
  AssignedTripStatus.inProgress => 'جارية',
  AssignedTripStatus.completed => 'مكتملة',
};

class TripStatusBadge extends StatelessWidget {
  const TripStatusBadge({super.key, required this.status});

  final AssignedTripStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, variant, icon) = switch (status) {
      AssignedTripStatus.scheduled => (
        'لم تُفتح',
        CaptainStatusVariant.neutral,
        Icons.lock_clock_rounded,
      ),
      AssignedTripStatus.openForBooking => (
        'الحجز مفتوح',
        CaptainStatusVariant.info,
        Icons.event_available_rounded,
      ),
      AssignedTripStatus.boarding => (
        'صعود',
        CaptainStatusVariant.warning,
        Icons.people_rounded,
      ),
      AssignedTripStatus.inProgress => (
        'جارية',
        CaptainStatusVariant.success,
        Icons.electric_car_rounded,
      ),
      AssignedTripStatus.completed => (
        'مكتملة',
        CaptainStatusVariant.neutral,
        Icons.check_circle_rounded,
      ),
    };

    return CaptainStatusChip(label: label, variant: variant, icon: icon);
  }
}

class TripFact extends StatelessWidget {
  const TripFact({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: CaptainColors.textSecondaryFor(context)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
