import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

import '../../domain/entities/driver_profile.dart';

/// Everything settled on this screen is drawn in the brand tone, so the two
/// tones that are *not* brand — amber and red — mean something by themselves.
/// A licence about to expire, one already expired, and a suspended account are
/// the only rows here that need acting on, and they are the only rows that
/// leave the brand colour.
class VerificationCard extends StatelessWidget {
  const VerificationCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CaptainSectionLabel(
          'الحالة والتوثيق',
          color: CaptainColors.primaryInkFor(context),
        ),
        CaptainListGroup(
          children: [
            _accountRow(context, profile.accountStatus),
            _licenseRow(context, profile),
          ],
        ),
      ],
    );
  }

  CaptainListRow _licenseRow(BuildContext context, DriverProfile profile) {
    final expiry = profile.licenseExpiryDate;
    if (expiry == null) {
      return CaptainListRow(
        icon: Icons.badge_outlined,
        label: 'رخصة القيادة',
        detail: 'غير مسجّلة',
        accentColor: CaptainColors.warningFor(context),
      );
    }

    final dateLabel = CaptainFormats.dayMonthYear(expiry);
    if (profile.isLicenseExpired) {
      return CaptainListRow(
        icon: Icons.error_rounded,
        label: 'رخصة القيادة منتهية',
        detail: 'انتهت في $dateLabel',
        accentColor: CaptainColors.dangerFor(context),
      );
    }
    if (profile.isLicenseExpiringSoon) {
      return CaptainListRow(
        icon: Icons.warning_amber_rounded,
        label: 'رخصة القيادة تنتهي قريباً',
        detail: 'تنتهي في $dateLabel — يُنصح بالتجديد',
        accentColor: CaptainColors.warningFor(context),
      );
    }
    return CaptainListRow(
      icon: Icons.check_circle_rounded,
      label: 'رخصة القيادة سارية',
      detail: 'حتى $dateLabel',
      accentColor: CaptainColors.primaryInkFor(context),
    );
  }

  CaptainListRow _accountRow(BuildContext context, DriverAccountStatus status) {
    final (icon, label, detail, color) = switch (status) {
      DriverAccountStatus.active => (
        Icons.check_circle_rounded,
        'الحساب نشط',
        'يمكنك استلام الرحلات',
        CaptainColors.primaryInkFor(context),
      ),
      DriverAccountStatus.suspended => (
        Icons.pause_circle_rounded,
        'الحساب موقوف مؤقتاً',
        'تواصل مع الإدارة',
        CaptainColors.warningFor(context),
      ),
      DriverAccountStatus.archived => (
        Icons.archive_rounded,
        'الحساب مؤرشف',
        'تواصل مع الإدارة',
        CaptainColors.dangerFor(context),
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
