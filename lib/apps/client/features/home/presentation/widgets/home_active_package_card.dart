import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/badge.dart';

/// The subscription the rider is riding on. Home renders this only when one
/// exists — plans they have not bought are left to the subscription screen.
class HomeActivePackageCard extends StatelessWidget {
  const HomeActivePackageCard({
    super.key,
    required this.package,
    required this.onTap,
  });

  final HomeActivePackageData package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: ClientColors.shadowFor(context).withAlpha(10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ClientColors.primaryFor(context).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.card_membership_rounded,
                        color: ClientColors.primaryFor(context),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _Titles(package: package)),
                    const AppBadge(text: 'ACTIVE'),
                  ],
                ),
                if (package.endDate != null) ...[
                  const SizedBox(height: 24),
                  _Validity(package: package),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.package});

  final HomeActivePackageData package;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          package.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        if (package.routeLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            package.routeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ],
    );
  }
}

/// How much of the subscription window is left — the only progress the
/// `subscriptions` table can honestly report.
class _Validity extends StatelessWidget {
  const _Validity({required this.package});

  final HomeActivePackageData package;

  @override
  Widget build(BuildContext context) {
    final remaining = package.remainingDays;
    final l10n = context.l10n;
    final label = remaining == 0
        ? l10n.home_expiresToday
        : remaining == 1
        ? l10n.home_dayLeft
        : l10n.home_daysLeft(remaining);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Valid until ${FormatUtil.date(context, package.endDate!)}',
              style: ClientTypography.bodySmall(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: ClientTypography.labelLarge(context).copyWith(
                color: ClientColors.textPrimaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (package.totalDays > 0) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: package.remainingRatio,
              minHeight: 8,
              backgroundColor: ClientColors.primaryFor(context).withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(
                ClientColors.primaryFor(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
