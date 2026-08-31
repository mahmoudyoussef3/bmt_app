import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';

import '../../domain/entities/business_health.dart';
import '../../domain/entities/business_overview.dart';
import 'overview_kit.dart';

/// Seven readings, each reduced to one word and one rule.
///
/// The point of the section is that an owner can stop reading it in three
/// seconds, so the amber and red readings **sort to the front** and "is
/// anything wrong" is answered by the first row alone. Everything under the
/// verdict — the measured figure and the threshold that graded it — is there
/// for the second question, not the first.
///
/// It is a list of bare rows rather than the three-column grid of bordered
/// cards it used to be: seven readings scan faster as seven lines, and a card
/// nested inside an already-bordered panel is the card-in-card the design
/// system rejects. The row is the kit's — the same one الرئيسية's «تقييمات
/// تحتاج متابعة» line uses — so a reading here and a reading there are the
/// same object.
class BusinessHealthSection extends StatelessWidget {
  const BusinessHealthSection({
    super.key,
    required this.overview,
    required this.onOpenModule,
  });

  final BusinessOverview overview;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final signals = [...overview.healthSignals]
      ..sort((a, b) => _rank(b.status).compareTo(_rank(a.status)));
    final needsAttention = signals.where((s) => s.needsAttention).length;

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessHealth,
      icon: DashboardIcons.health,
      title: 'صحة النشاط',
      subtitle: needsAttention == 0
          ? 'كل المؤشرات ضمن المستهدف'
          : '$needsAttention من ${signals.length} مؤشرات تحتاج انتباهك',
      collapsedSummary: _CollapsedSummary(signals: signals),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < signals.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: DashboardColors.divider(context)),
            _HealthRow(
              signal: signals[i],
              onOpen: () => onOpenModule(_specFor(signals[i].metric).route),
            ),
          ],
        ],
      ),
    );
  }

  /// Critical first, then warning, then healthy, then unmeasurable — "we can't
  /// tell" belongs at the bottom, not beside a clean bill of health.
  static int _rank(BusinessHealthStatus status) => switch (status) {
    BusinessHealthStatus.critical => 3,
    BusinessHealthStatus.warning => 2,
    BusinessHealthStatus.healthy => 1,
    BusinessHealthStatus.unknown => 0,
  };
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.signal, required this.onOpen});

  final BusinessHealthSignal signal;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(signal.metric);
    return OverviewLinkRow(
      icon: spec.icon,
      label: spec.label,
      detail: signal.detail,
      value: signal.reading,
      note: statusLabel(signal.status),
      tone: statusColor(context, signal.status),
      onTap: onOpen,
    );
  }
}

class _CollapsedSummary extends StatelessWidget {
  const _CollapsedSummary({required this.signals});

  final List<BusinessHealthSignal> signals;

  @override
  Widget build(BuildContext context) {
    final critical = signals
        .where((s) => s.status == BusinessHealthStatus.critical)
        .length;
    final warning = signals
        .where((s) => s.status == BusinessHealthStatus.warning)
        .length;

    final text = switch ((critical, warning)) {
      (0, 0) => 'كل المؤشرات سليمة',
      (0, final w) => '$w مؤشراً يحتاج متابعة',
      (final c, 0) => '$c مؤشراً حرجاً',
      (final c, final w) => '$c حرج · $w يحتاج متابعة',
    };

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: DashboardColors.mutedInk(context)),
    );
  }
}

/// The four verdicts, in the dashboard's shared status colours — so "warning"
/// here is the same amber as a warning badge anywhere else in the console.
Color statusColor(BuildContext context, BusinessHealthStatus status) {
  final palette = DashboardChartPalette.of(context);
  return switch (status) {
    BusinessHealthStatus.healthy => palette.positive,
    BusinessHealthStatus.warning => palette.warning,
    BusinessHealthStatus.critical => palette.negative,
    BusinessHealthStatus.unknown => palette.neutral,
  };
}

String statusLabel(BusinessHealthStatus status) => switch (status) {
  BusinessHealthStatus.healthy => 'سليم',
  BusinessHealthStatus.warning => 'يحتاج متابعة',
  BusinessHealthStatus.critical => 'حرج',
  BusinessHealthStatus.unknown => 'غير متاح',
};

/// How a metric presents itself: what to call it, its glyph, and the screen
/// that can do something about it.
class _MetricSpec {
  final String label;
  final IconData icon;
  final String route;

  const _MetricSpec({
    required this.label,
    required this.icon,
    required this.route,
  });
}

_MetricSpec _specFor(BusinessHealthMetric metric) => switch (metric) {
  BusinessHealthMetric.revenueTrend => const _MetricSpec(
    label: 'اتجاه الإيراد',
    icon: DashboardIcons.trend,
    route: DashboardRoutes.payments,
  ),
  BusinessHealthMetric.occupancy => const _MetricSpec(
    label: 'نسبة الإشغال',
    icon: DashboardIcons.occupancy,
    route: DashboardRoutes.trips,
  ),
  BusinessHealthMetric.cancellationRate => const _MetricSpec(
    label: 'معدل الإلغاء',
    icon: DashboardIcons.bookings,
    route: DashboardRoutes.bookings,
  ),
  BusinessHealthMetric.delayedTrips => const _MetricSpec(
    label: 'رحلات متأخرة',
    icon: DashboardIcons.time,
    route: DashboardRoutes.liveOps,
  ),
  BusinessHealthMetric.openRefunds => const _MetricSpec(
    label: 'طلبات الاسترداد',
    icon: DashboardIcons.wallet,
    route: DashboardRoutes.wallet,
  ),
  BusinessHealthMetric.fleetUtilisation => const _MetricSpec(
    label: 'استغلال الأسطول',
    icon: DashboardIcons.fleet,
    route: DashboardRoutes.fleet,
  ),
  BusinessHealthMetric.collectionHealth => const _MetricSpec(
    label: 'صحة التحصيل',
    icon: DashboardIcons.payments,
    route: DashboardRoutes.payments,
  ),
};
