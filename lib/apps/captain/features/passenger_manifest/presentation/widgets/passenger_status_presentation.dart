import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

import '../../domain/entities/passenger.dart';

/// How a boarding status looks, in one place.
///
/// This mapping previously existed four times over — the card's status rail,
/// its badge, the status sheet's options and the filter chips each re-derived
/// it, and the rail had drifted onto raw Material colours while the other three
/// used the brand tokens. A captain reading "صعد" green on a badge and a
/// different green on the rail beside it is reading two answers to one
/// question.
extension PassengerStatusPresentation on PassengerBoardingStatus {
  String get label => switch (this) {
    PassengerBoardingStatus.boarded => 'صعد',
    PassengerBoardingStatus.pending => 'بانتظار',
    PassengerBoardingStatus.late => 'متأخر',
    PassengerBoardingStatus.absent => 'غائب',
    PassengerBoardingStatus.cancelled => 'ملغي',
  };

  Color get color => switch (this) {
    PassengerBoardingStatus.boarded => CaptainColors.success,
    PassengerBoardingStatus.pending => CaptainColors.primary,
    PassengerBoardingStatus.late => CaptainColors.warning,
    PassengerBoardingStatus.absent => CaptainColors.error,
    PassengerBoardingStatus.cancelled => CaptainColors.offline,
  };

  IconData get icon => switch (this) {
    PassengerBoardingStatus.boarded => Icons.check_circle_rounded,
    PassengerBoardingStatus.pending => Icons.hourglass_top_rounded,
    PassengerBoardingStatus.late => Icons.timer_rounded,
    PassengerBoardingStatus.absent => Icons.person_off_rounded,
    PassengerBoardingStatus.cancelled => Icons.cancel_rounded,
  };
}

/// The statuses a captain can assign, in the order they are offered.
///
/// Ordered by how often they're actually used on a boarding door, not by the
/// enum's declaration order.
const kAssignablePassengerStatuses = <PassengerBoardingStatus>[
  PassengerBoardingStatus.boarded,
  PassengerBoardingStatus.pending,
  PassengerBoardingStatus.late,
  PassengerBoardingStatus.absent,
  PassengerBoardingStatus.cancelled,
];

/// The statuses offered as list filters — every assignable one except
/// `cancelled`, which is not a state the captain filters a live manifest by.
const kFilterablePassengerStatuses = <PassengerBoardingStatus>[
  PassengerBoardingStatus.boarded,
  PassengerBoardingStatus.pending,
  PassengerBoardingStatus.late,
  PassengerBoardingStatus.absent,
];
