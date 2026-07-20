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
    PassengerBoardingStatus.absent => 'غائب',
    PassengerBoardingStatus.cancelled => 'ملغي',
  };

  Color get color => switch (this) {
    PassengerBoardingStatus.boarded => CaptainColors.success,
    PassengerBoardingStatus.pending => CaptainColors.primary,
    PassengerBoardingStatus.absent => CaptainColors.error,
    PassengerBoardingStatus.cancelled => CaptainColors.offline,
  };

  IconData get icon => switch (this) {
    PassengerBoardingStatus.boarded => Icons.check_circle_rounded,
    PassengerBoardingStatus.pending => Icons.hourglass_top_rounded,
    PassengerBoardingStatus.absent => Icons.person_off_rounded,
    PassengerBoardingStatus.cancelled => Icons.cancel_rounded,
  };

  /// What tapping this status is about to do, spelled out before it happens.
  String get confirmation => switch (this) {
    PassengerBoardingStatus.boarded => 'تأكيد صعود الراكب إلى المركبة.',
    PassengerBoardingStatus.pending => 'إرجاع الراكب إلى قائمة الانتظار.',
    PassengerBoardingStatus.absent =>
      'تسجيل الراكب كغائب. استخدمها بعد انتظاره عند نقطة التجميع.',
    PassengerBoardingStatus.cancelled => '',
  };
}

/// The statuses a captain can assign at the boarding door, in the order they
/// are offered — by how often they're actually used, not by declaration order.
///
/// `cancelled` is **not** among them: cancelling a booking releases the seat
/// and settles the payment, which the trip's own flows do properly. Writing
/// the status straight from here would strand a paid seat as unavailable, so
/// a cancellation made elsewhere still *displays* here, but the captain
/// cannot make one.
const kAssignablePassengerStatuses = <PassengerBoardingStatus>[
  PassengerBoardingStatus.boarded,
  PassengerBoardingStatus.pending,
  PassengerBoardingStatus.absent,
];

/// The statuses offered as list filters.
const kFilterablePassengerStatuses = <PassengerBoardingStatus>[
  PassengerBoardingStatus.boarded,
  PassengerBoardingStatus.pending,
  PassengerBoardingStatus.absent,
];
