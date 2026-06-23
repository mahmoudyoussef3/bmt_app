import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/referral_record.dart';

String referralStatusLabel(ReferralStatus status) => switch (status) {
  ReferralStatus.pendingRegistration => 'بانتظار التسجيل',
  ReferralStatus.registered => 'مُسجَّل',
  ReferralStatus.firstOrderCompleted => 'أتمّ أول طلب',
  ReferralStatus.rewardGranted => 'تم منح المكافأة',
  ReferralStatus.unknown => 'غير معروف',
};

class ReferralStatusChip extends StatelessWidget {
  const ReferralStatusChip({super.key, required this.status});

  final ReferralStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReferralStatus.pendingRegistration => AppStatusColors.onNeutralContainer,
      ReferralStatus.registered => AppStatusColors.onInfoContainer,
      ReferralStatus.firstOrderCompleted => AppStatusColors.onWarningContainer,
      ReferralStatus.rewardGranted => AppStatusColors.onSuccessContainer,
      ReferralStatus.unknown => AppStatusColors.onNeutralContainer,
    };
    return StatusChip(
      label: referralStatusLabel(status),
      color: color.withAlpha(28),
      textColor: color,
    );
  }
}

class ReferralRewardStatusChip extends StatelessWidget {
  const ReferralRewardStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'granted' => AppStatusColors.onSuccessContainer,
      'pending' => AppStatusColors.onWarningContainer,
      _ => AppStatusColors.onNeutralContainer,
    };
    final label = switch (status) {
      'granted' => 'ممنوحة',
      'pending' => 'قيد الانتظار',
      _ => status,
    };
    return StatusChip(
      label: label,
      color: color.withAlpha(28),
      textColor: color,
    );
  }
}
