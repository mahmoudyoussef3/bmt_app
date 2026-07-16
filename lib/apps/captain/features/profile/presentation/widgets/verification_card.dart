import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_detail_row.dart';

import '../../domain/entities/driver_profile.dart';
import 'verification_status_badge.dart';

/// The captain's real verification standing — license expiry and account
/// status, both already recorded on `drivers` and already fetched by
/// `DriverProfileDataSource`. No fabricated "verified" badge: an expired or
/// soon-to-expire license shows exactly that, since a captain who can't
/// legally drive needs to know before it becomes a problem on the road.
class VerificationCard extends StatelessWidget {
  const VerificationCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CaptainDesignTokens.s12),
                decoration: BoxDecoration(
                  color: CaptainColors.primary.withValues(alpha: 0.1),
                  borderRadius: CaptainDesignTokens.br12,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 18,
                  color: CaptainColors.primary,
                ),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              Expanded(
                child: Text(
                  'التحقق والتوثيق',
                  style: CaptainTypography.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: CaptainColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s16),
          _LicenseStatusRow(profile: profile),
          const SizedBox(height: CaptainDesignTokens.s12),
          _AccountStatusRow(status: profile.accountStatus),
          if (profile.employeeCode != null) ...[
            const SizedBox(height: CaptainDesignTokens.s12),
            CaptainDetailRow(
              label: 'كود الكابتن',
              value: profile.employeeCode!,
              bottomSpacing: 0,
            ),
          ],
          if (profile.hireDate != null) ...[
            const SizedBox(height: CaptainDesignTokens.s12),
            CaptainDetailRow(
              label: 'كابتن منذ',
              value: CaptainFormats.monthAndYear(profile.hireDate!),
              bottomSpacing: 0,
            ),
          ],
        ],
      ),
    );
  }
}

class _LicenseStatusRow extends StatelessWidget {
  const _LicenseStatusRow({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final expiry = profile.licenseExpiryDate;
    if (expiry == null) {
      return const VerificationStatusBadge(
        icon: Icons.badge_outlined,
        label: 'رخصة القيادة',
        detail: 'غير مسجّلة',
        color: Colors.grey,
      );
    }

    final dateLabel = CaptainFormats.dayMonthYear(expiry);
    if (profile.isLicenseExpired) {
      return VerificationStatusBadge(
        icon: Icons.error_rounded,
        label: 'رخصة القيادة منتهية',
        detail: 'انتهت في $dateLabel',
        color: CaptainColors.error,
      );
    }
    if (profile.isLicenseExpiringSoon) {
      return VerificationStatusBadge(
        icon: Icons.warning_amber_rounded,
        label: 'رخصة القيادة تنتهي قريباً',
        detail: 'تنتهي في $dateLabel — يُنصح بالتجديد',
        color: CaptainColors.warning,
      );
    }
    return VerificationStatusBadge(
      icon: Icons.check_circle_rounded,
      label: 'رخصة القيادة سارية',
      detail: 'حتى $dateLabel',
      color: CaptainColors.success,
    );
  }
}

class _AccountStatusRow extends StatelessWidget {
  const _AccountStatusRow({required this.status});

  final DriverAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      DriverAccountStatus.active => (
        Icons.check_circle_rounded,
        'الحساب نشط',
        CaptainColors.success,
      ),
      DriverAccountStatus.suspended => (
        Icons.pause_circle_rounded,
        'الحساب موقوف مؤقتاً',
        CaptainColors.warning,
      ),
      DriverAccountStatus.archived => (
        Icons.archive_rounded,
        'الحساب مؤرشف',
        CaptainColors.error,
      ),
    };
    return VerificationStatusBadge(icon: icon, label: label, color: color);
  }
}
