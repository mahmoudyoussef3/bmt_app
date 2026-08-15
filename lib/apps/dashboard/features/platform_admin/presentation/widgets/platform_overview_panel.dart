import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/usecases/platform_admin_usecases.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// How the platform is doing, above the list of what it contains.
///
/// The office list answers "what exists". This answers the three questions that
/// actually bring a platform admin to this screen — is the platform growing,
/// which tenants are carrying it, and what is broken right now — none of which
/// can be read off a list of lifetime counts.
///
/// Laid out worst-news-first: the attention queue sits above the charts,
/// because a dead marketplace listing is worth more of the operator's attention
/// than a revenue line, and putting the pleasant number first would bury it.
class PlatformOverviewPanel extends StatelessWidget {
  const PlatformOverviewPanel({
    super.key,
    required this.analytics,
    required this.offices,
    required this.isLoading,
    required this.error,
    required this.onWindowChanged,
    required this.onRetry,
    required this.onOpenOffice,
  });

  final PlatformAnalytics? analytics;
  final List<PlatformOffice> offices;
  final bool isLoading;
  final String? error;
  final ValueChanged<int> onWindowChanged;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenOffice;

  @override
  Widget build(BuildContext context) {
    final data = analytics;

    if (data == null) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: error != null
            ? _AnalyticsError(message: error!, onRetry: onRetry)
            : const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.medium),
                  child: CircularProgressIndicator(),
                ),
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WindowSelector(
          windowDays: data.windowDays,
          isLoading: isLoading,
          generatedAt: data.generatedAt,
          onChanged: onWindowChanged,
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.small),
          _AnalyticsError(message: error!, onRetry: onRetry, isStale: true),
        ],
        const SizedBox(height: AppSpacing.medium),
        _HeadlineKpis(totals: data.totals, windowDays: data.windowDays),
        const SizedBox(height: AppSpacing.medium),
        _AttentionQueue(
          items: data.attentionFor(offices),
          onOpenOffice: onOpenOffice,
        ),
        const SizedBox(height: AppSpacing.medium),
        _TrendAndLeaders(analytics: data, offices: offices),
        const SizedBox(height: AppSpacing.medium),
        _PortfolioBreakdown(totals: data.totals, windowDays: data.windowDays),
      ],
    );
  }
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({
    required this.message,
    required this.onRetry,
    this.isStale = false,
  });

  final String message;
  final VoidCallback onRetry;

  /// True when older numbers are still on screen beneath this — the message
  /// then has to say they are old, or the operator reads stale figures as current.
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error, size: 20),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              isStale ? 'الأرقام المعروضة قديمة: $message' : message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

/// The analytics window. Only the aggregates move with it — the office list
/// below is unaffected, so switching windows never rearranges the screen.
class _WindowSelector extends StatelessWidget {
  const _WindowSelector({
    required this.windowDays,
    required this.isLoading,
    required this.generatedAt,
    required this.onChanged,
  });

  final int windowDays;
  final bool isLoading;
  final DateTime? generatedAt;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'نطاق التحليل',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.small),
        SegmentedButton<int>(
          segments: [
            for (final days in GetPlatformAnalyticsUseCase.windowChoices)
              ButtonSegment(value: days, label: Text('$days يوم')),
          ],
          selected: {windowDays},
          showSelectedIcon: false,
          onSelectionChanged: isLoading
              ? null
              : (selection) => onChanged(selection.first),
        ),
        const SizedBox(width: AppSpacing.small),
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        const Spacer(),
        if (generatedAt case final at? when !isLoading)
          Text(
            'حُدّثت ${_timeLabel(at)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }

  String _timeLabel(DateTime at) {
    final local = at.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

/// The six numbers worth reading before anything else.
class _HeadlineKpis extends StatelessWidget {
  const _HeadlineKpis({required this.totals, required this.windowDays});

  final PlatformTotals totals;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final occupancy = totals.occupancyRate;

    final cards = <Widget>[
      DashboardKpiCard(
        label: 'إيراد آخر $windowDays يوم',
        value: totals.revenueRecentLabel,
        detail: 'الإجمالي ${totals.revenueTotalLabel}',
        icon: Icons.payments_outlined,
      ),
      DashboardKpiCard(
        label: 'حجوزات آخر $windowDays يوم',
        value: '${totals.bookingsRecent}',
        detail: 'الإجمالي ${totals.bookingsTotal}',
        icon: Icons.confirmation_number_outlined,
      ),
      DashboardKpiCard(
        label: 'مكاتب نشطة تجارياً',
        value: '${totals.trading} / ${totals.offices}',
        detail: 'خاملة ${totals.idle} · لم تبدأ ${totals.neverTraded}',
        icon: Icons.storefront_outlined,
        color: totals.trading == 0 ? scheme.error : null,
      ),
      DashboardKpiCard(
        label: 'رحلات متاحة للحجز',
        value: '${totals.tripsUpcoming}',
        detail: 'نُفّذت ${totals.tripsRecent} خلال المدة',
        icon: Icons.event_available_outlined,
        color: totals.tripsUpcoming == 0 ? scheme.error : null,
      ),
      DashboardKpiCard(
        label: 'مدفوعات بانتظار المراجعة',
        value: '${totals.paymentsAwaitingReview}',
        detail: totals.awaitingAmountLabel,
        icon: Icons.hourglass_bottom_outlined,
        color: totals.paymentsAwaitingReview > 0 ? scheme.tertiary : null,
      ),
      DashboardKpiCard(
        label: 'إشغال المقاعد',

        value: occupancy == null
            ? '—'
            : '${(occupancy * 100).toStringAsFixed(0)}%',
        detail: '${totals.seatsSold} من ${totals.seatsOffered} مقعد',
        icon: Icons.event_seat_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.small,
          mainAxisSpacing: AppSpacing.small,
          childAspectRatio: 3.4,
          children: cards,
        );
      },
    );
  }
}

/// Everything broken right now, worst first.
///
/// Collapses to a single reassuring line when empty — an always-present empty
/// panel trains the operator to skip the region, and then they skip it on the
/// day it is not empty.
class _AttentionQueue extends StatelessWidget {
  const _AttentionQueue({required this.items, required this.onOpenOffice});

  final List<OfficeAttention> items;
  final ValueChanged<String> onOpenOffice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: scheme.primary, size: 20),
            const SizedBox(width: AppSpacing.small),
            Text(
              'لا توجد مكاتب تحتاج تدخلاً الآن.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final critical = items
        .where((i) => i.severity == AttentionSeverity.critical)
        .length;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.priority_high_rounded,
                size: 20,
                color: critical > 0 ? scheme.error : scheme.tertiary,
              ),
              const SizedBox(width: AppSpacing.xSmall),
              Text(
                'يحتاج تدخلاً (${items.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (critical > 0) ...[
                const SizedBox(width: AppSpacing.small),
                Text(
                  'منها $critical حرج',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          for (final item in items)
            _AttentionRow(
              item: item,
              onOpen: () => onOpenOffice(item.officeId),
            ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item, required this.onOpen});

  final OfficeAttention item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (item.severity) {
      AttentionSeverity.critical => scheme.error,
      AttentionSeverity.warning => scheme.tertiary,
      AttentionSeverity.info => scheme.onSurfaceVariant,
    };

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: item.officeName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' — '),
                        TextSpan(
                          text: item.title,
                          style: TextStyle(color: color),
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    item.detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Demand over time, beside who is producing it.
///
/// Side by side on purpose: a rising line means something different depending
/// on whether one office is carrying it or all of them are, and that comparison
/// is the whole point of a platform view.
class _TrendAndLeaders extends StatelessWidget {
  const _TrendAndLeaders({required this.analytics, required this.offices});

  final PlatformAnalytics analytics;
  final List<PlatformOffice> offices;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final trend = [
      for (final point in analytics.trend)
        ChartDatum(
          label: '${point.day.day}/${point.day.month}',
          value: point.bookings.toDouble(),
          color: scheme.primary,
        ),
    ];

    final leaders = [
      for (final office in offices)
        if (analytics.metricsFor(office.id) case final m?
            when m.revenueRecent > 0)
          ChartDatum(
            label: office.name,
            value: m.revenueRecent,
            color: scheme.primary,
          ),
    ].toList()..sort((a, b) => b.value.compareTo(a.value));

    return LayoutBuilder(
      builder: (context, constraints) {
        final trendCard = _ChartCard(
          title: 'الحجوزات اليومية عبر المنصة',
          subtitle:
              'إجمالي ${analytics.totals.bookingsRecent} حجز '
              'خلال ${analytics.windowDays} يوم',
          child: DashboardLineChart(data: trend),
        );
        final leadersCard = _ChartCard(
          title: 'المكاتب الأعلى إيراداً',
          subtitle: leaders.isEmpty
              ? 'لا يوجد إيراد معتمد خلال المدة'
              : 'إيراد معتمد خلال ${analytics.windowDays} يوم',
          child: DashboardRankedBars(data: leaders.take(6).toList()),
        );

        if (constraints.maxWidth < 820) {
          return Column(
            children: [
              trendCard,
              const SizedBox(height: AppSpacing.medium),
              leadersCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: trendCard),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: leadersCard),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    );
  }
}

/// How the office portfolio splits across the axes that matter, as counts the
/// operator can act on rather than a chart they can only look at.
class _PortfolioBreakdown extends StatelessWidget {
  const _PortfolioBreakdown({required this.totals, required this.windowDays});

  final PlatformTotals totals;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع المكاتب',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.small,
            children: [
              _Breakdown(label: 'إجمالي', value: totals.offices),
              _Breakdown(label: 'نشطة', value: totals.active),
              _Breakdown(label: 'معروضة في السوق', value: totals.listed),
              _Breakdown(label: 'قيد التجهيز', value: totals.draft),
              _Breakdown(label: 'مسحوبة', value: totals.unlisted),
              _Breakdown(
                label: 'موقوفة',
                value: totals.suspended + totals.paused,
                tint: totals.suspended + totals.paused > 0
                    ? scheme.error
                    : null,
              ),
              _Breakdown(
                label: 'بانتظار العرض',
                value: totals.awaitingListing,
                tint: totals.awaitingListing > 0 ? scheme.tertiary : null,
              ),
              _Breakdown(
                label: 'معروضة بلا رحلات',
                value: totals.listedWithoutTrips,
                tint: totals.listedWithoutTrips > 0 ? scheme.error : null,
              ),
              _Breakdown(
                label: 'بلا مسؤول نشط',
                value: totals.withoutAdmin,
                tint: totals.withoutAdmin > 0 ? scheme.error : null,
              ),
              _Breakdown(
                label: 'رحلات فات موعدها',
                value: totals.tripsStale,
                tint: totals.tripsStale > 0 ? scheme.tertiary : null,
              ),
              _Breakdown(label: 'تذاكر دعم مفتوحة', value: totals.ticketsOpen),
              _Breakdown(
                label: 'طلبات كباتن معلقة',
                value: totals.captainRequestsPending,
              ),
              _Breakdown(
                label: 'مكاتب جديدة خلال $windowDays يوم',
                value: totals.onboardedInWindow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.label, required this.value, this.tint});

  final String label;
  final int value;

  /// Set only when a non-zero value is itself a problem, so colour means
  /// "look at this" and never merely "this is a number".
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: tint,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
