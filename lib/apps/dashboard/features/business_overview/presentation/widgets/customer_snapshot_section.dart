import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';

import '../../domain/entities/business_overview.dart';
import 'overview_format.dart';
import 'overview_metric.dart';

/// Section 6 — the customer base, in seven figures.
///
/// Counted off the account id on each booking, over a rolling 30 days. Guest
/// bookings carry no account and are excluded throughout rather than collapsed
/// into one phantom customer that would outrank every real one.
///
/// Summary only. Cohorts, funnels and per-customer history stay in Reports and
/// in the wallet's customer directory, which is what the two links go to.
class CustomerSnapshotSection extends StatelessWidget {
  const CustomerSnapshotSection({
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

    final active = overview.activeCustomerIds(days: _window).length;
    final fresh = overview.newCustomerIds(days: _window).length;
    final returning = overview.returningCustomerIds(days: _window).length;
    final inactive = overview.inactiveCustomers(days: _window);
    final retention = overview.retentionRate(days: _window);
    final top = overview.topCustomer(days: _window);

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessCustomers,
      icon: DashboardIcons.customers,
      title: 'قاعدة العملاء',
      subtitle: 'آخر ٣٠ يوماً · التحليل التفصيلي في التقارير',
      trailing: TextButton.icon(
        onPressed: () => onOpenModule(DashboardRoutes.reports),
        icon: const Icon(DashboardIcons.openModule, size: 16),
        label: const Text('افتح التقارير'),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      ),
      collapsedSummary: Text(
        '$active عميلاً نشطاً · $fresh جديد · عودة ${percentOrDash(retention)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      child: OverviewMetricGrid(
        children: [
          OverviewMetric(
            label: 'عملاء نشطون',
            value: count(active),
            hint: 'حجزوا خلال ٣٠ يوم',
            tone: palette.active,
            onTap: () => onOpenModule(DashboardRoutes.bookings),
          ),
          OverviewMetric(
            label: 'عملاء جدد',
            value: count(fresh),
            hint: 'أول حجز لهم في هذه الفترة',
            tone: fresh > 0 ? palette.positive : null,
            onTap: () => onOpenModule(DashboardRoutes.bookings),
          ),
          OverviewMetric(
            label: 'عملاء عائدون',
            value: count(returning),
            hint: 'كانوا قد حجزوا من قبل',
            onTap: () => onOpenModule(DashboardRoutes.bookings),
          ),
          OverviewMetric(
            label: 'عملاء غير نشطين',
            value: count(inactive),
            hint: 'لم يحجزوا خلال ٣٠ يوم',
            tone: inactive > 0 ? palette.warning : null,
            onTap: () => onOpenModule(DashboardRoutes.wallet),
          ),
          OverviewMetric(
            label: 'نسبة العودة',
            value: percentOrDash(retention),
            hint: 'من نشطي الفترة',
            onTap: () => onOpenModule(DashboardRoutes.reports),
          ),
          OverviewMetric(
            label: 'إجمالي العملاء',
            value: count(overview.totalCustomers),
            hint: 'حسابات لها حجز واحد على الأقل',
            onTap: () => onOpenModule(DashboardRoutes.wallet),
          ),
          OverviewMetric(
            label: 'أعلى عميل إنفاقاً',
            value: top?.name ?? '—',
            hint: top == null
                ? 'لا مدفوعات مقبولة في الفترة'
                : '${money(top.spend)} من ${count(top.bookings)} حجز',
            onTap: () => onOpenModule(DashboardRoutes.wallet),
          ),
        ],
      ),
    );
  }
}
