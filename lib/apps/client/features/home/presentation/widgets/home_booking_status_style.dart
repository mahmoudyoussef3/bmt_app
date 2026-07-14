import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

/// How each booking status looks. Amber reads as "waiting on us", blue as
/// "settled", green as "happening now" — the same language the rest of the
/// journey UI already speaks.
extension HomeBookingStatusStyle on HomeBookingStatus {
  ClientJourneyStatus get badge => switch (this) {
    HomeBookingStatus.underReview => ClientJourneyStatus.departing,
    HomeBookingStatus.confirmed => ClientJourneyStatus.upcoming,
    HomeBookingStatus.onBoard => ClientJourneyStatus.active,
  };

  Color get accent => switch (this) {
    HomeBookingStatus.underReview => ClientColors.journeyAmber,
    HomeBookingStatus.confirmed => ClientColors.primary,
    HomeBookingStatus.onBoard => ClientColors.journeyGreen,
  };

  IconData get icon => switch (this) {
    HomeBookingStatus.underReview => Icons.hourglass_top_rounded,
    HomeBookingStatus.confirmed => Icons.verified_rounded,
    HomeBookingStatus.onBoard => Icons.directions_bus_filled_rounded,
  };

  /// A pulsing dot belongs to a trip that is actually under way.
  bool get isPulsing => this == HomeBookingStatus.onBoard;
}
