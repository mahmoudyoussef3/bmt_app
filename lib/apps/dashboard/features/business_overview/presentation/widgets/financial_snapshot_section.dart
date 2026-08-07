import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/business_overview.dart';
import 'overview_format.dart';
import 'overview_metric.dart';

/// Section 4 — the money, at a height an owner can read in ten seconds.
///
/// **This does not replace Finance, and is careful not to imply that it has.**
/// Finance owns the three-statement model and its control identity; what is
/// here are that model's *components* over a rolling 30 days, each labelled
/// with the same words Finance uses for it, plus one line out to the module
/// that can prove them. Two figures in particular are quoted definitions
/// rather than new arithmetic: "الإيراد بعد المستردات" is Finance's accrual
/// revenue (`soldFare − refundsTotal`) and "بعد الحوافز" is its
/// `contributionAfterIncentives`. Neither is a net-profit figure, and neither
/// is presented as one.
class FinancialSnapshotSection extends StatelessWidget {
  const FinancialSnapshotSection({
    super.key,
    required this.overview,
    required this.onOpenModule,
  });

  final BusinessOverview overview;
  final ValueChanged<String> onOpenModule;

  static const _window = 30;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasWallet = overview.has(BusinessDataSource.wallet);

    final collected = overview.collected(days: _window);
    final refunds = overview.refundsSettled(days: _window);
    final incentives = overview.promotionalCost(days: _window);
    final series = overview.revenueSeries(days: _window);

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessFinancial,
      icon: DashboardIcons.financial,
      title: 'الملخص المالي',
      subtitle: 'آخر ٣٠ يوماً · التفاصيل الكاملة في وحدة المالية',
      trailing: TextButton.icon(
        onPressed: () => onOpenModule(DashboardRoutes.payments),
        icon: const Icon(DashboardIcons.openModule, size: 16),
        label: const Text('افتح المالية'),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      ),
      collapsedSummary: Text(
        'محصّل ${money(collected)} · لم يُحصّل ${money(overview.outstanding)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OverviewMetricGrid(
            children: [
              OverviewMetric(
                label: 'إيراد الحجوزات المحصّل',
                value: money(collected),
                hint: 'مدفوعات مقبولة خلال ٣٠ يوم',
                tone: palette.positive,
                onTap: () => onOpenModule(DashboardRoutes.payments),
              ),
              OverviewMetric(
                label: 'مستحقات لم تُحصّل',
                value: money(overview.outstanding),
                hint: 'حجوزات قائمة بانتظار الدفع',
                tone: overview.outstanding > 0 ? palette.warning : null,
                onTap: () => onOpenModule(DashboardRoutes.paymentVerification),
              ),
              OverviewMetric(
                label: 'مستردات مسوّاة',
                value: hasWallet ? money(refunds) : '—',
                hint: hasWallet ? 'خلال ٣٠ يوم' : 'تعذّر تحميل المحافظ',
                tone: refunds > 0 ? palette.negative : null,
                onTap: () => onOpenModule(DashboardRoutes.wallet),
              ),
              OverviewMetric(
                label: 'كاش باك وحوافز',
                value: hasWallet ? money(incentives) : '—',
                hint: hasWallet
                    ? 'تكلفة ترويجية بلا نقد مقابل'
                    : 'تعذّر تحميل المحافظ',
                onTap: () => onOpenModule(DashboardRoutes.wallet),
              ),
              OverviewMetric(
                label: 'التزام المحافظ',
                value: hasWallet ? money(overview.walletLiability) : '—',
                hint: hasWallet
                    ? 'أرصدة مستحقة للعملاء الآن'
                    : 'تعذّر تحميل المحافظ',
                onTap: () => onOpenModule(DashboardRoutes.wallet),
              ),
              OverviewMetric(
                label: 'الإيراد بعد المستردات',
                value: money(overview.netRevenue(days: _window)),
                hint: 'ما بيعه المكتب فعلياً خلال ٣٠ يوم',
                tone: palette.positive,
                onTap: () => onOpenModule(DashboardRoutes.payments),
              ),
              OverviewMetric(
                label: 'بعد الحوافز',
                value: money(overview.contribution(days: _window)),
                hint: 'الإيراد ناقص تكلفة الكاش باك',
                onTap: () => onOpenModule(DashboardRoutes.payments),
              ),
              OverviewMetric(
                label: 'نسبة التحصيل',
                value: percentOrDash(overview.collectionRate(days: _window)),
                hint: 'من قيمة حجوزات ٣٠ يوم',
                onTap: () => onOpenModule(DashboardRoutes.payments),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'اتجاه التحصيل اليومي',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xSmall),
          if (collected <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
              child: Text(
                'لا مدفوعات مقبولة خلال آخر ٣٠ يوماً.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            DashboardLineChart(
              lineColor: palette.positive,
              data: [
                for (final point in series)
                  ChartDatum(
                    label: '${point.day.day}/${point.day.month}',
                    value: point.value,
                    color: scheme.primary,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
