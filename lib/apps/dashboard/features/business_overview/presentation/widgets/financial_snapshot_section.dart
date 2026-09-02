import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_stacked_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/business_overview.dart';
import '../models/overview_window.dart';
import 'overview_format.dart';
import 'overview_kit.dart';

/// The money, at a height an owner can read in ten seconds.
///
/// **This does not replace Finance, and is careful not to imply that it has.**
/// Finance owns the three-statement model and its control identity; what is
/// here are that model's *components* over the selected window, each labelled
/// with the same words Finance uses, plus one line out to the module that can
/// prove them. Two figures are quoted definitions rather than new arithmetic:
/// «الإيراد بعد المستردات» is Finance's accrual revenue (`soldFare −
/// refundsTotal`) and «بعد الحوافز» its `contributionAfterIncentives`. Neither
/// is a net-profit figure, and neither is presented as one.
///
/// ## The shape
///
/// Three registers, in الرئيسية's own vocabulary. **How much of what we billed
/// arrived** is a track, because that is a ratio and Home draws every ratio as
/// one. **What the period left us with** is an equation read across the panel,
/// because three of its five figures are inputs and two are results — a grid of
/// equal cells says the opposite. **Everything else** is a divided strip.
///
/// What this replaced: eight identical bordered boxes nested inside an already
/// bordered panel, plus an unlabelled line chart drawing the same series the
/// revenue panel next door now draws properly.
class FinancialSnapshotSection extends StatelessWidget {
  const FinancialSnapshotSection({
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
    final hasWallet = overview.has(BusinessDataSource.wallet);

    final collected = overview.collected(days: days);
    final refunds = overview.refundsSettled(days: days);
    final incentives = overview.promotionalCost(days: days);
    final net = overview.netRevenue(days: days);
    final contribution = overview.contribution(days: days);
    final rate = overview.collectionRate(days: days);

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessFinancial,
      icon: DashboardIcons.financial,
      title: 'الأداء المالي',
      subtitle: '${window.title} · التفاصيل الكاملة في وحدة المالية',
      trailing: OverviewPanelAction(
        label: 'المالية',
        onPressed: () => onOpenModule(DashboardRoutes.payments),
      ),
      collapsedSummary: Text(
        'محصّل ${money(collected)} · مستحق الآن ${money(overview.outstanding)}',
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
            label: 'نسبة التحصيل',
            ratio: rate,
            tone: (rate ?? 1) >= 0.85 ? palette.positive : palette.warning,
            trailingNote: 'من حجوزات ${window.label}',
            notes: [
              'محصّل ${money(collected)}',
              'مستحق الآن ${money(overview.outstanding)}',
            ],
            emptyNote: 'لم تُسجَّل حجوزات قابلة للتحصيل في ${window.title}.',
            onTap: () => onOpenModule(DashboardRoutes.paymentVerification),
          ),
          const Divider(height: AppSpacing.large),
          _RevenueEquation(
            collected: collected,
            refunds: refunds,
            incentives: incentives,
            net: net,
            contribution: contribution,
            hasWallet: hasWallet,
          ),
          const Divider(height: AppSpacing.large),
          OverviewCellStrip(
            cells: [
              OverviewCell(
                icon: DashboardIcons.paymentReview,
                label: 'لم تُحصّل',
                value: money(overview.outstanding),
                note: 'كل الفترات',
                tone: overview.outstanding > 0 ? palette.warning : null,
                onTap: () => onOpenModule(DashboardRoutes.paymentVerification),
              ),
              OverviewCell(
                icon: DashboardIcons.wallet,
                label: 'مستردات مسوّاة',
                value: hasWallet ? money(refunds) : '—',
                note: hasWallet ? window.label : 'تعذّر تحميل المحافظ',
                tone: refunds > 0 ? palette.negative : null,
                onTap: () => onOpenModule(DashboardRoutes.wallet),
              ),
              OverviewCell(
                icon: DashboardIcons.revenue,
                label: 'كاش باك وحوافز',
                value: hasWallet ? money(incentives) : '—',
                note: hasWallet ? 'بلا نقد مقابل' : 'تعذّر تحميل المحافظ',
                onTap: () => onOpenModule(DashboardRoutes.wallet),
              ),
              OverviewCell(
                icon: DashboardIcons.walletActive,
                label: 'التزام المحافظ',
                value: hasWallet ? money(overview.walletLiability) : '—',
                note: hasWallet ? 'مستحق للعملاء الآن' : 'تعذّر تحميل المحافظ',
                onTap: () => onOpenModule(DashboardRoutes.wallet),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `المحصّل − المستردات = بعد المستردات − الحوافز = بعد الحوافز`, read across
/// the panel. Each operator travels with the figure it applies to, so a wrap at
/// a narrow width never orphans a lone «=» at the head of a line.
class _RevenueEquation extends StatelessWidget {
  const _RevenueEquation({
    required this.collected,
    required this.refunds,
    required this.incentives,
    required this.net,
    required this.contribution,
    required this.hasWallet,
  });

  final double collected;
  final double refunds;
  final double incentives;
  final double net;
  final double contribution;
  final bool hasWallet;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The picture of the arithmetic, above the arithmetic itself. Five
        // amounts read across a panel are five amounts; one bar split three
        // ways is the sentence they add up to — *this is what the period
        // collected, and this is what was given back out of it* — and it is
        // the only place on the page where a 550-pound refund against a
        // 108,000-pound month is visible as the rounding error it is.
        if (hasWallet && collected > 0) ...[
          DashboardStackedBar(
            title: 'تركيبة المحصّل',
            trailingNote: money(collected),
            segments: [
              DashboardBarSegment(
                label: 'بعد الحوافز',
                value: contribution < 0 ? 0 : contribution,
                valueLabel: money(contribution),
                color: palette.positive,
              ),
              DashboardBarSegment(
                label: 'الحوافز',
                value: incentives,
                valueLabel: money(incentives),
                color: palette.accent,
              ),
              DashboardBarSegment(
                label: 'المستردات',
                value: refunds,
                valueLabel: money(refunds),
                color: palette.negative,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            OverviewFigure(label: 'المحصّل', value: money(collected)),
            OverviewTerm(
              symbol: '−',
              label: 'المستردات',
              value: hasWallet ? money(refunds) : '—',
              color: refunds > 0 ? palette.negative : null,
            ),
            // Both results are dashes without the wallet, not the collected
            // figure passed through. `refundsSettled` returns 0 when the feed
            // is missing, so printing `net` here would state that nothing was
            // refunded — an unmeasured zero, which is the one thing this page
            // does not do.
            OverviewTerm(
              symbol: '=',
              label: 'بعد المستردات',
              value: hasWallet ? money(net) : '—',
              color: hasWallet ? palette.positive : null,
              emphasised: true,
            ),
            OverviewTerm(
              symbol: '−',
              label: 'الحوافز',
              value: hasWallet ? money(incentives) : '—',
            ),
            OverviewTerm(
              symbol: '=',
              label: 'بعد الحوافز',
              value: hasWallet ? money(contribution) : '—',
              emphasised: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'ليست أرباحاً: لا تُخصم من هذه الأرقام أي تكاليف تشغيل — الوقود، '
          'الرواتب، الصيانة. التسوية الكاملة في وحدة المالية.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DashboardColors.faintInk(context),
          ),
        ),
      ],
    );
  }
}
