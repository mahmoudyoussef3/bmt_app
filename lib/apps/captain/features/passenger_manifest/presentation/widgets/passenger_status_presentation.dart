import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

import '../../domain/entities/passenger.dart';

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
