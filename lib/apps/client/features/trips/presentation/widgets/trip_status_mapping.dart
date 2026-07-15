import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Maps [TripStatus] onto the shared [ClientJourneyStatus] badge system so
/// trip status always uses the correct bg/fg contrast pair — never the same
/// color for both, which made the previous `StatusChip` usage unreadable.
ClientJourneyStatus journeyStatusFor(TripStatus status) {
  return switch (status) {
    TripStatus.upcoming => ClientJourneyStatus.upcoming,
    TripStatus.inProgress => ClientJourneyStatus.active,
    TripStatus.completed => ClientJourneyStatus.completed,
    TripStatus.cancelled => ClientJourneyStatus.cancelled,
  };
}

/// A driver-card badge label derived from the trip's own status — replaces
/// a previous hardcoded "Available" that showed even mid-trip or cancelled.
String driverBadgeLabelFor(BuildContext context, TripStatus status) {
  return switch (status) {
    TripStatus.upcoming => context.l10n.trips_driverBadgeAssigned,
    TripStatus.inProgress => context.l10n.trips_driverBadgeEnRoute,
    TripStatus.completed => context.l10n.trips_driverBadgeCompleted,
    TripStatus.cancelled => context.l10n.trips_driverBadgeCancelled,
  };
}

/// The trip-card status pill text ("Upcoming", "In progress"…), kept in the
/// presentation layer since [TripData] itself must stay framework-free.
String statusLabelFor(BuildContext context, TripStatus status) {
  return switch (status) {
    TripStatus.upcoming => context.l10n.trips_filterUpcoming,
    TripStatus.inProgress => context.l10n.trips_statusInProgress,
    TripStatus.completed => context.l10n.trips_filterCompleted,
    TripStatus.cancelled => context.l10n.trips_filterCancelled,
  };
}

/// The payment-status pill text ("Paid", "Pending"…) for a trip card.
String paymentLabelFor(BuildContext context, PaymentStatus status) {
  return switch (status) {
    PaymentStatus.paid => context.l10n.trips_paymentPaid,
    PaymentStatus.pending => context.l10n.trips_paymentPending,
    PaymentStatus.underReview => context.l10n.trips_paymentUnderReview,
    PaymentStatus.refunded => context.l10n.trips_paymentRefunded,
    PaymentStatus.failed => context.l10n.trips_paymentFailed,
    PaymentStatus.cancelled => context.l10n.trips_filterCancelled,
  };
}

Color driverBadgeColorFor(TripStatus status) {
  return switch (status) {
    TripStatus.upcoming => ClientColors.primary,
    TripStatus.inProgress => ClientColors.journeyCyan,
    TripStatus.completed => ClientColors.journeySlate,
    TripStatus.cancelled => ClientColors.journeyRed,
  };
}
