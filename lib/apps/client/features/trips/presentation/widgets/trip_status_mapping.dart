import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

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
String driverBadgeLabelFor(TripStatus status) {
  return switch (status) {
    TripStatus.upcoming => 'Assigned',
    TripStatus.inProgress => 'En route',
    TripStatus.completed => 'Trip complete',
    TripStatus.cancelled => 'Trip cancelled',
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
