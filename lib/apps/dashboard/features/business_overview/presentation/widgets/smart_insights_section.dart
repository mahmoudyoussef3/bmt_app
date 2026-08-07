import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/business_insight.dart';

/// Section 3 — what the numbers mean, in sentences.
///
/// ## The layout is the future-proofing
///
/// This renders a *list of [BusinessInsight]s*. It does not know or care how
/// any of them were produced. When a copilot, a forecaster or a recommendation
/// engine is added, it appends items carrying [InsightSource.assistant] and
/// this file does not change — the badge on the card already distinguishes a
/// measured finding from a generated one, and the action already routes
/// wherever the producer pointed it.
///
/// An empty section is a real answer, not a gap: the rules below refuse to
/// speak without enough evidence, so "nothing stands out this week" is what a
/// quiet week is supposed to look like.
class SmartInsightsSection extends StatelessWidget {
  const SmartInsightsSection({
    super.key,
    required this.insights,
    required this.onOpenModule,
  });

  final List<BusinessInsight> insights;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      sectionId: DashboardSectionIds.businessInsights,
      icon: DashboardIcons.insight,
      title: 'قراءات وتوصيات',
      subtitle: insights.isEmpty
          ? null
          : '${insights.length} قراءة مستخرجة من بيانات مكتبك',
      collapsedSummary: Text(
        insights.isEmpty
            ? 'لا توجد قراءات هذا الأسبوع'
            : insights.first.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      child: insights.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.insight,
              title: 'لا توجد قراءات بارزة',
              message:
                  'تظهر هنا القراءات فور توفر بيانات كافية للمقارنة — أسبوعان '
                  'من الحجوزات أو ثلاث رحلات على الخط الواحد.',
            )
          : Column(
              children: [
                for (final insight in insights)
                  _InsightCard(
                    insight: insight,
                    onOpenModule: onOpenModule,
                  ),
              ],
            ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.onOpenModule});

  final BusinessInsight insight;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = DashboardChartPalette.of(context);
    final tone = switch (insight.severity) {
      InsightSeverity.positive => palette.positive,
      InsightSeverity.warning => palette.warning,
      InsightSeverity.critical => palette.negative,
      InsightSeverity.informational => palette.active,
    };
    final action = insight.action;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: DashboardColors.well(context),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: DashboardColors.border(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              child: Icon(_iconFor(insight.kind), size: 18, color: tone),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          insight.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (insight.source == InsightSource.assistant) ...[
                        const SizedBox(width: AppSpacing.xSmall),
                        _SourceBadge(tone: palette.accent),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    insight.detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: AppSpacing.xSmall),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => onOpenModule(action.route),
                        icon: const Icon(DashboardIcons.openModule, size: 16),
                        label: Text(action.label),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.small,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marks a sentence a model wrote rather than a rule measured. Shown only for
/// assistant output — a derived finding needs no disclaimer.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'مساعد ذكي',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

IconData _iconFor(InsightKind kind) => switch (kind) {
  InsightKind.routePerformance => DashboardIcons.routes,
  InsightKind.demandPattern => DashboardIcons.time,
  InsightKind.revenueComparison => DashboardIcons.trend,
  InsightKind.refundTrend => DashboardIcons.wallet,
  InsightKind.driverPerformance => DashboardIcons.captain,
  InsightKind.occupancyOpportunity => DashboardIcons.occupancy,
  InsightKind.customerRetention => DashboardIcons.customers,
  InsightKind.general => DashboardIcons.insight,
};
