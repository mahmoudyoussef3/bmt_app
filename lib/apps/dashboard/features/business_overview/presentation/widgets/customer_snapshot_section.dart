import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/business_overview.dart';
import '../models/overview_window.dart';
import 'overview_format.dart';
import 'overview_kit.dart';

/// The customer base: how many, how new, and whether they come back.
///
/// Counted off the account id on each booking, over the selected window. Guest
/// bookings carry no account and are excluded throughout rather than collapsed
/// into one phantom customer that would outrank every real one.
///
/// Retention leads because it is the only figure here that is a *verdict* — the
/// rest is inventory — and الرئيسية draws every verdict-shaped ratio as a
/// track. It used to be the fifth of seven equal tiles, one of which was «أعلى
/// عميل إنفاقاً» crammed into a cell built for a number, with the amount
/// demoted to the hint line underneath.
///
/// Summary only. Cohorts, funnels and per-customer history stay in Reports and
/// in the wallet's customer directory, which is what the links go to.
class CustomerSnapshotSection extends StatelessWidget {
  const CustomerSnapshotSection({
    super.key,
    required this.overview,
    required this.window,
    required this.onOpenModule,
  });

  final BusinessOverview overview;
  final OverviewWindow window;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final days = window.days;

    final active = overview.activeCustomerIds(days: days).length;
    final fresh = overview.newCustomerIds(days: days).length;
    final returning = overview.returningCustomerIds(days: days).length;
    final inactive = overview.inactiveCustomers(days: days);
    final retention = overview.retentionRate(days: days);
    final top = overview.topCustomer(days: days);

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessCustomers,
      icon: DashboardIcons.customersActive,
      title: 'قاعدة العملاء',
      subtitle: '${window.title} · التحليل التفصيلي في التقارير',
      trailing: OverviewPanelAction(
        label: 'التقارير',
        onPressed: () => onOpenModule(DashboardRoutes.reports),
      ),
      collapsedSummary: Text(
        '${count(active)} عميلاً نشطاً · ${count(fresh)} جديد · '
        'عودة ${percentOrDash(retention)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OverviewTrackRow(
            label: 'نسبة العودة',
            ratio: retention,
            tone: (retention ?? 0) >= 0.4 ? palette.positive : palette.warning,
            trailingNote: 'من نشطي الفترة',
            notes: [
              '${count(returning)} عائد من ${count(active)} نشط',
              '${count(fresh)} عميل جديد',
            ],
            emptyNote: 'لا حجوزات بحسابات عملاء في ${window.title}.',
            onTap: () => onOpenModule(DashboardRoutes.reports),
          ),
          const Divider(height: AppSpacing.large),
          OverviewCellStrip(
            cells: [
              OverviewCell(
                icon: DashboardIcons.customers,
                label: 'نشطون',
                value: count(active),
                note: 'حجزوا في الفترة',
                onTap: () => onOpenModule(DashboardRoutes.bookings),
              ),
              OverviewCell(
                icon: DashboardIcons.passenger,
                label: 'جدد',
                value: count(fresh),
                note: 'أول حجز لهم',
                tone: fresh > 0 ? palette.positive : null,
                onTap: () => onOpenModule(DashboardRoutes.bookings),
              ),
              OverviewCell(
                icon: DashboardIcons.time,
                label: 'غير نشطين',
                value: count(inactive),
                note: 'لم يحجزوا',
                tone: inactive > 0 ? palette.warning : null,
                onTap: () => onOpenModule(DashboardRoutes.wallet),
              ),
              OverviewCell(
                icon: DashboardIcons.customersActive,
                label: 'إجمالي العملاء',
                value: count(overview.totalCustomers),
                note: 'بحجز واحد فأكثر',
                onTap: () => onOpenModule(DashboardRoutes.wallet),
              ),
            ],
          ),
          const Divider(height: AppSpacing.large),
          OverviewLinkRow(
            icon: DashboardIcons.ranking,
            label: 'أعلى عميل إنفاقاً',
            detail: top?.name ?? 'لا مدفوعات مقبولة في الفترة',
            value: top == null ? '—' : money(top.spend),
            note: top == null
                ? null
                : '${count(top.bookings)} حجز في ${window.label}',
            tone: top == null ? null : palette.positive,
            onTap: top == null
                ? null
                : () => onOpenModule(DashboardRoutes.wallet),
          ),
        ],
      ),
    );
  }
}
