import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

import '../../domain/entities/passenger.dart';

/// How heavily a status badge is drawn.
///
/// Boarding status deliberately does **not** change hue. A manifest whose rows
/// flip between green, red and amber is tiring to scan on a phone, so every
/// status stays in the app's primary blue and is told apart by its icon, its
/// label, and how filled its badge is.
enum PassengerStatusEmphasis { solid, tinted, outlined, muted }

extension PassengerStatusPresentation on PassengerBoardingStatus {
  String get label => switch (this) {
    PassengerBoardingStatus.boarded => 'صعد',
    PassengerBoardingStatus.pending => 'بانتظار',
    PassengerBoardingStatus.absent => 'غائب',
    PassengerBoardingStatus.cancelled => 'ملغي',
  };

  Color get color => CaptainColors.primary;

  PassengerStatusEmphasis get emphasis => switch (this) {
    PassengerBoardingStatus.boarded => PassengerStatusEmphasis.solid,
    PassengerBoardingStatus.pending => PassengerStatusEmphasis.tinted,
    PassengerBoardingStatus.absent => PassengerStatusEmphasis.outlined,
    PassengerBoardingStatus.cancelled => PassengerStatusEmphasis.muted,
  };

  IconData get icon => switch (this) {
    PassengerBoardingStatus.boarded => Icons.check_circle_rounded,
    PassengerBoardingStatus.pending => Icons.hourglass_top_rounded,
    PassengerBoardingStatus.absent => Icons.person_off_rounded,
    PassengerBoardingStatus.cancelled => Icons.cancel_rounded,
  };

  String get confirmation => switch (this) {
    PassengerBoardingStatus.boarded => 'تأكيد صعود الراكب إلى المركبة.',
    PassengerBoardingStatus.pending => 'إرجاع الراكب إلى قائمة الانتظار.',
    PassengerBoardingStatus.absent =>
      'تسجيل الراكب كغائب. استخدمها بعد انتظاره عند نقطة التجميع.',
    PassengerBoardingStatus.cancelled => '',
  };
}

const kAssignablePassengerStatuses = <PassengerBoardingStatus>[
  PassengerBoardingStatus.boarded,
  PassengerBoardingStatus.pending,
  PassengerBoardingStatus.absent,
];

const kFilterablePassengerStatuses = <PassengerBoardingStatus>[
  PassengerBoardingStatus.boarded,
  PassengerBoardingStatus.pending,
  PassengerBoardingStatus.absent,
];
