import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/business_health.dart';
import '../../domain/entities/business_overview.dart';

/// Section 2 — seven readings, each reduced to one word and one rule.
///
/// The point of the section is that an owner can stop reading it in three
/// seconds: the amber and red cards sort to the front, so "is anything wrong"
/// is answered by the top-left corner alone. Everything under the verdict —
/// the measured figure and the threshold that graded it — is there for the
/// second question, not the first.
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
    final signals = overview.healthSignals;
    final needsAttention = signals.where((s) => s.needsAttention).length;

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessHealth,
      icon: DashboardIcons.health,
      title: 'صحة النشاط',
      subtitle: needsAttention == 0
          ? 'كل المؤشرات ضمن المستهدف'
          : '$needsAttention من ${signals.length} مؤشرات تحتاج انتباهك',
      collapsedSummary: _CollapsedSummary(signals: signals),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1000
              ? 3
              : width >= 640
              ? 2
              : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: signals.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.small,
              mainAxisSpacing: AppSpacing.small,
              mainAxisExtent: 92,
            ),
            itemBuilder: (context, index) => _HealthCard(
              signal: signals[index],
              onOpen: () => onOpenModule(_specFor(signals[index].metric).route),
            ),
          );
        },
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.signal, required this.onOpen});

  final BusinessHealthSignal signal;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = statusColor(context, signal.status);
    final spec = _specFor(signal.metric);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onOpen,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: DashboardColors.well(context),
            borderRadius: radius,
            border: Border.all(color: DashboardColors.border(context)),
          ),
          child: Row(
            children: [
              
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Icon(spec.icon, size: 18, color: tone),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spec.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xSmall),
                        Text(
                          signal.reading,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _StatusPill(status: signal.status),
                        const SizedBox(width: AppSpacing.xSmall),
                        Expanded(
                          child: Text(
                            signal.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BusinessHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
        ),
      ),
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
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
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
