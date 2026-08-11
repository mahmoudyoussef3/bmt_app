import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

import '../../domain/entities/driver_profile.dart';

class VerificationCard extends StatelessWidget {
  const VerificationCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CaptainSectionLabel('التحقق والتوثيق'),
        CaptainListGroup(
          children: [
            _licenseRow(profile),
            _accountRow(profile.accountStatus),
            if (profile.hireDate != null)
              CaptainListRow(
                icon: Icons.event_available_rounded,
                label: 'كابتن منذ',
                value: CaptainFormats.monthAndYear(profile.hireDate!),
              ),
          ],
        ),
      ],
    );
  }

  CaptainListRow _licenseRow(DriverProfile profile) {
    final expiry = profile.licenseExpiryDate;
    if (expiry == null) {
      return const CaptainListRow(
        icon: Icons.badge_outlined,
        label: 'رخصة القيادة',
        detail: 'غير مسجّلة',
        accentColor: CaptainColors.offline,
      );
    }

    final dateLabel = CaptainFormats.dayMonthYear(expiry);
    if (profile.isLicenseExpired) {
      return CaptainListRow(
        icon: Icons.error_rounded,
        label: 'رخصة القيادة منتهية',
        detail: 'انتهت في $dateLabel',
        accentColor: CaptainColors.error,
      );
    }
    if (profile.isLicenseExpiringSoon) {
      return CaptainListRow(
        icon: Icons.warning_amber_rounded,
        label: 'رخصة القيادة تنتهي قريباً',
        detail: 'تنتهي في $dateLabel — يُنصح بالتجديد',
        accentColor: CaptainColors.warning,
      );
    }
    return CaptainListRow(
      icon: Icons.check_circle_rounded,
      label: 'رخصة القيادة سارية',
      detail: 'حتى $dateLabel',
      accentColor: CaptainColors.success,
    );
  }

  CaptainListRow _accountRow(DriverAccountStatus status) {
    final (icon, label, detail, color) = switch (status) {
      DriverAccountStatus.active => (
        Icons.check_circle_rounded,
        'الحساب نشط',
        'يمكنك استلام الرحلات',
        CaptainColors.success,
      ),
      DriverAccountStatus.suspended => (
        Icons.pause_circle_rounded,
        'الحساب موقوف مؤقتاً',
        'تواصل مع الإدارة',
        CaptainColors.warning,
      ),
      DriverAccountStatus.archived => (
        Icons.archive_rounded,
        'الحساب مؤرشف',
        'تواصل مع الإدارة',
        CaptainColors.error,
      ),
    };
    return CaptainListRow(
      icon: icon,
      label: label,
      detail: detail,
      accentColor: color,
    );
  }
}
