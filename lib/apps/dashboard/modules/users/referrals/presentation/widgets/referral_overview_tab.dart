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
              color: const Color(0xFF2563EB),
            ),
            DashboardKpiCard(
              label: 'إجمالي الإحالات',
              value: referralArNum(analytics.totalReferrals),
              icon: Icons.group_add_rounded,
              color: const Color(0xFF7C3AED),
            ),
            DashboardKpiCard(
              label: 'قيد الانتظار',
              value: referralArNum(analytics.pendingReferrals),
              icon: Icons.hourglass_bottom_rounded,
              color: const Color(0xFFD97706),
            ),
            DashboardKpiCard(
              label: 'أتمّوا أول طلب',
              value: referralArNum(
                analytics.firstOrderCompleted + analytics.rewardGranted,
              ),
              icon: Icons.shopping_bag_rounded,
              color: const Color(0xFF0EA5E9),
            ),
            DashboardKpiCard(
              label: 'مكافآت مُنحت',
              value: referralArNum(analytics.rewardGranted),
              icon: Icons.card_giftcard_rounded,
              color: const Color(0xFF16A34A),
            ),
            DashboardKpiCard(
              label: 'معدل التحويل',
              value: referralArPercent(analytics.conversionRate),
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF16A34A),
            ),
            DashboardKpiCard(
              label: 'مكافآت المُحيلين',
              value: '${referralArNum(analytics.referrerRewards)} $currency',
              icon: Icons.person_rounded,
              color: const Color(0xFF2563EB),
            ),
            DashboardKpiCard(
              label: 'مكافآت المدعوين',
              value: '${referralArNum(analytics.referredRewards)} $currency',
              icon: Icons.person_add_alt_1_rounded,
              color: const Color(0xFF7C3AED),
            ),
            DashboardKpiCard(
              label: 'إجمالي المكافآت الموزعة',
              value: '${referralArNum(analytics.totalRewards)} $currency',
              icon: Icons.payments_rounded,
              color: const Color(0xFF16A34A),
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
              child: DashboardDonutChart(data: _statusBreakdown()),
            );
            final rewards = DashboardPanel(
              icon: Icons.leaderboard_rounded,
              title: 'توزيع المكافآت',
              subtitle: 'مكافآت المُحيلين مقابل المدعوين',
              child: DashboardRankedBars(data: _rewardSplit()),
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

  List<ChartDatum> _statusBreakdown() {
    return [
      ChartDatum(
        label: 'قيد الانتظار',
        value: analytics.pendingReferrals.toDouble(),
        color: const Color(0xFFD97706),
      ),
      ChartDatum(
        label: 'أتمّ أول طلب',
        value: analytics.firstOrderCompleted.toDouble(),
        color: const Color(0xFF0EA5E9),
      ),
      ChartDatum(
        label: 'ممنوحة',
        value: analytics.rewardGranted.toDouble(),
        color: const Color(0xFF16A34A),
      ),
    ];
  }

  List<ChartDatum> _rewardSplit() {
    return [
      ChartDatum(
        label: 'المُحيلون',
        value: analytics.referrerRewards,
        color: const Color(0xFF2563EB),
      ),
      ChartDatum(
        label: 'المدعوون',
        value: analytics.referredRewards,
        color: const Color(0xFF7C3AED),
      ),
    ];
  }
}
