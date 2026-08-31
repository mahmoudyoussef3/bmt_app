import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/business_insight.dart';

/// What the numbers mean, in sentences — the third panel in the decision rail.
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
        insights.isEmpty ? 'لا توجد قراءات هذا الأسبوع' : insights.first.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DashboardColors.mutedInk(context),
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
                  _InsightCard(insight: insight, onOpenModule: onOpenModule),
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
    final text = Theme.of(context).textTheme;
    final tone = switch (insight.severity) {
      InsightSeverity.positive => AppStatusTone.success,
      InsightSeverity.warning => AppStatusTone.warning,
      InsightSeverity.critical => AppStatusTone.error,
      InsightSeverity.informational => AppStatusTone.info,
    };
    final style = DashboardColors.status(context, tone);
    final action = insight.action;
    final radius = BorderRadius.circular(10);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DashboardColors.panel(context),
          borderRadius: radius,
          border: Border.all(color: DashboardColors.border(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The record tile's glyph square, to the pixel — a reading and a
            // queue item are the same kind of object on this page and on
            // الرئيسية, and the only colour on either is this mark.
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: style.tint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DashboardColors.statusLine(context, tone),
                ),
              ),
              child: Icon(_iconFor(insight.kind), size: 18, color: style.ink),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          insight.title,
                          style: text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (insight.source == InsightSource.assistant) ...[
                        const SizedBox(width: AppSpacing.xSmall),
                        const _SourceBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    insight.detail,
                    style: text.labelSmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                      height: 1.5,
                    ),
                  ),
                  if (action != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => onOpenModule(action.route),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.small,
                          ),
                        ),
                        child: Text(action.label),
                      ),
                    ),
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
  const _SourceBadge();

  @override
  Widget build(BuildContext context) {
    final style = DashboardColors.status(context, AppStatusTone.special);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: DashboardColors.statusLine(context, AppStatusTone.special),
        ),
      ),
      child: Text(
        'مساعد ذكي',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: style.ink,
          fontWeight: FontWeight.w800,
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
