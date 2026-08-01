import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';

import '../../domain/entities/referral_analytics.dart';
import '../../domain/entities/referral_reward_config.dart';
import 'referral_format.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';

class ReferralOverviewTab extends StatelessWidget {
  const ReferralOverviewTab({
    super.key,
    required this.analytics,
    required this.config,
  });

  final ReferralAnalytics analytics;
  final ReferralRewardConfig config;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final currency = config.currency;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardKpiGrid(
          children: [
            DashboardKpiCard(
              label: 'أكواد الإحالة',
              value: referralArNum(analytics.totalCodes),
              icon: Icons.qr_code_2_rounded,
              color: palette.active,
            ),
            DashboardKpiCard(
              label: 'إجمالي الإحالات',
              value: referralArNum(analytics.totalReferrals),
              icon: Icons.group_add_rounded,
              color: palette.accent,
            ),
            DashboardKpiCard(
              label: 'قيد الانتظار',
              value: referralArNum(analytics.pendingReferrals),
              icon: Icons.hourglass_bottom_rounded,
              color: palette.warning,
            ),
            DashboardKpiCard(
              label: 'أتمّوا أول طلب',
              value: referralArNum(
                analytics.firstOrderCompleted + analytics.rewardGranted,
              ),
              icon: Icons.shopping_bag_rounded,
              color: palette.positive,
            ),
            DashboardKpiCard(
              label: 'مكافآت مُنحت',
              value: referralArNum(analytics.rewardGranted),
              icon: Icons.card_giftcard_rounded,
              color: palette.positive,
            ),
            DashboardKpiCard(
              label: 'معدل التحويل',
              value: referralArPercent(analytics.conversionRate),
              icon: Icons.trending_up_rounded,
              color: palette.positive,
            ),
            DashboardKpiCard(
              label: 'مكافآت المُحيلين',
              value: '${referralArNum(analytics.referrerRewards)} $currency',
              icon: Icons.person_rounded,
              color: palette.active,
            ),
            DashboardKpiCard(
              label: 'مكافآت المدعوين',
              value: '${referralArNum(analytics.referredRewards)} $currency',
              icon: Icons.person_add_alt_1_rounded,
              color: palette.accent,
            ),
            DashboardKpiCard(
              label: 'إجمالي المكافآت الموزعة',
              value: '${referralArNum(analytics.totalRewards)} $currency',
              icon: Icons.payments_rounded,
              color: palette.positive,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final breakdown = DashboardPanel(
              icon: Icons.donut_large_rounded,
              title: 'توزيع حالات الإحالة',
              subtitle: 'قيد الانتظار مقابل المكتملة والممنوحة',
              child: DashboardDonutChart(data: _statusBreakdown(palette)),
            );
            final rewards = DashboardPanel(
              icon: Icons.leaderboard_rounded,
              title: 'توزيع المكافآت',
              subtitle: 'مكافآت المُحيلين مقابل المدعوين',
              child: DashboardRankedBars(data: _rewardSplit(palette)),
            );
            if (constraints.maxWidth < 980) {
              return Column(
                children: [
                  breakdown,
                  const SizedBox(height: AppSpacing.medium),
                  rewards,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: breakdown),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: rewards),
              ],
            );
          },
        ),
      ],
    );
  }

  List<ChartDatum> _statusBreakdown(DashboardChartPalette palette) {
    return [
      ChartDatum(
        label: 'قيد الانتظار',
        value: analytics.pendingReferrals.toDouble(),
        color: palette.warning,
      ),
      ChartDatum(
        label: 'أتمّ أول طلب',
        value: analytics.firstOrderCompleted.toDouble(),
        color: palette.positive,
      ),
      ChartDatum(
        label: 'ممنوحة',
        value: analytics.rewardGranted.toDouble(),
        color: palette.positive,
      ),
    ];
  }

  List<ChartDatum> _rewardSplit(DashboardChartPalette palette) {
    return [
      ChartDatum(
        label: 'المُحيلون',
        value: analytics.referrerRewards,
        color: palette.active,
      ),
      ChartDatum(
        label: 'المدعوون',
        value: analytics.referredRewards,
        color: palette.accent,
      ),
    ];
  }
}
