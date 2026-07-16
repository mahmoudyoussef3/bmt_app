import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

import '../../domain/entities/driver_profile.dart';

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
              Text(
                'التحقق والتوثيق',
                style: CaptainTypography.titleSmall(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: CaptainColors.textPrimaryFor(context),
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
            _Fact(label: 'كود الكابتن', value: profile.employeeCode!),
          ],
          if (profile.hireDate != null) ...[
            const SizedBox(height: CaptainDesignTokens.s12),
            _Fact(
              label: 'كابتن منذ',
              value: DateFormat('MMMM y', 'ar').format(profile.hireDate!),
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
      return const _StatusBadge(
        icon: Icons.badge_outlined,
        label: 'رخصة القيادة',
        detail: 'غير مسجّلة',
        color: Colors.grey,
      );
    }

    final dateLabel = DateFormat('d MMMM y', 'ar').format(expiry);
    if (profile.isLicenseExpired) {
      return _StatusBadge(
        icon: Icons.error_rounded,
        label: 'رخصة القيادة منتهية',
        detail: 'انتهت في $dateLabel',
        color: CaptainColors.error,
      );
    }
    if (profile.isLicenseExpiringSoon) {
      return _StatusBadge(
        icon: Icons.warning_amber_rounded,
        label: 'رخصة القيادة تنتهي قريباً',
        detail: 'تنتهي في $dateLabel — يُنصح بالتجديد',
        color: CaptainColors.warning,
      );
    }
    return _StatusBadge(
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
    return _StatusBadge(icon: icon, label: label, color: color);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: CaptainDesignTokens.br12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CaptainTypography.labelLarge(
                    context,
                  ).copyWith(color: color, fontWeight: FontWeight.w800),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: CaptainTypography.labelSmall(
                      context,
                    ).copyWith(color: CaptainColors.textSecondaryFor(context)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: CaptainTypography.bodyMedium(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: CaptainTypography.bodyMedium(context).copyWith(
            color: CaptainColors.textPrimaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
