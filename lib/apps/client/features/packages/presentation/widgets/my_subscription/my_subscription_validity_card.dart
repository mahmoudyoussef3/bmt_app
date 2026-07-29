import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/my_subscription.dart';
import '../details/package_info_panel.dart';
import '../details/package_section_title.dart';
import '../package_detail_row.dart';

/// Start/expiry dates plus a days-remaining progress bar.
class MySubscriptionValidityCard extends StatelessWidget {
  const MySubscriptionValidityCard({super.key, required this.subscription});

  final MySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final remaining = subscription.remainingDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PackageSectionTitle(title: l10n.packages_validityPeriod),
        const SizedBox(height: 10),
        PackageInfoPanel(
          child: Column(
            children: [
              PackageDetailRow(
                label: l10n.mySubscription_started,
                value: _formatDate(context, subscription.startDate),
              ),
              const SizedBox(height: 8),
              PackageDetailRow(
                label: l10n.mySubscription_expires,
                value: _formatDate(context, subscription.endDate),
              ),
              if (subscription.totalDays > 0) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    remaining == 0
                        ? l10n.home_expiresToday
                        : remaining == 1
                        ? l10n.home_dayLeft
                        : l10n.home_daysLeft(remaining),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ClientColors.textSecondaryFor(context),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: subscription.remainingRatio,
                    minHeight: 8,
                    backgroundColor: scheme.primary.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '—';
    return FormatUtil.date(context, date);
  }
}
