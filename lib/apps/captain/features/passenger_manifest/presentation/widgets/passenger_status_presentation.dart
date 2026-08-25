import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

import '../../domain/entities/passenger.dart';

/// How heavily a status badge is drawn.
///
/// Boarding status used to stay in one primary blue for every state, told apart
/// only by its icon and how filled the badge was, so a manifest would not flip
/// between hues as it filled up. The imported design overturns that, and it is
/// right to: the manifest is the one screen where the captain is not reading
/// rows, they are looking for the ones still outstanding before they close the
/// door. Green for boarded and red for absent lets that scan happen in one
/// pass; a column of identical blue badges forced them to read every label.
///
/// The hue is spent *here and nowhere else*. Trip stage stays in one calm blue
/// (see `CaptainTripStagePalette`) — a trip changing colour at every step is
/// alarm fatigue, whereas boarding status is a genuine two-way sort.
enum PassengerStatusEmphasis { solid, tinted, outlined, muted }

extension PassengerStatusPresentation on PassengerBoardingStatus {
  String get label => switch (this) {
    PassengerBoardingStatus.boarded => 'صعد',
    PassengerBoardingStatus.pending => 'بانتظار',
    PassengerBoardingStatus.absent => 'غائب',
    PassengerBoardingStatus.cancelled => 'ملغي',
  };

  Color colorFor(BuildContext context) => switch (this) {
    PassengerBoardingStatus.boarded => CaptainColors.successFor(context),
    PassengerBoardingStatus.absent => CaptainColors.dangerFor(context),
    PassengerBoardingStatus.pending => CaptainColors.textSecondaryFor(context),
    PassengerBoardingStatus.cancelled => CaptainColors.textSecondaryFor(context),
  };

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
