import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';

import '../../domain/entities/referral_record.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

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
      ReferralStatus.pendingRegistration =>
        context.status(AppStatusTone.neutral).ink,
      ReferralStatus.registered => context.status(AppStatusTone.info).ink,
      ReferralStatus.firstOrderCompleted =>
        context.status(AppStatusTone.warning).ink,
      ReferralStatus.rewardGranted => context.status(AppStatusTone.success).ink,
      ReferralStatus.unknown => context.status(AppStatusTone.neutral).ink,
    };
    return DashboardStatusChip(
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
      'granted' => context.status(AppStatusTone.success).ink,
      'pending' => context.status(AppStatusTone.warning).ink,
      _ => context.status(AppStatusTone.neutral).ink,
    };
    final label = switch (status) {
      'granted' => 'ممنوحة',
      'pending' => 'قيد الانتظار',
      _ => status,
    };
    return DashboardStatusChip(
      label: label,
      color: color.withAlpha(28),
      textColor: color,
    );
  }
}
