import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/business_overview.dart';
import 'overview_format.dart';

/// The page's opening line: whose business, how it is doing, and when the
/// figures were taken.
///
/// Not a copy of Home's banner. Home greets an operator starting a shift and
/// hands them the trip planner; this states a verdict — today's takings and how
/// many indicators are off target — because the owner opening this tab has
/// already decided what they came to find out.
///
/// The "as of" time is not decoration. Every figure below is a snapshot taken
/// at one instant, and an owner comparing this page with a module they opened
/// ten minutes ago deserves to know which of the two is older.
class BusinessOverviewHeader extends StatelessWidget {
  const BusinessOverviewHeader({
    super.key,
    required this.office,
    required this.overview,
    this.onRefresh,
    this.isRefreshing = false,
  });

  final OfficeContext office;
  final BusinessOverview overview;
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onHero = DashboardColors.onHero(context);
    final officeName = office.officeName.trim().isEmpty
        ? 'مكتبك'
        : office.officeName.trim();

    final offTarget = overview.healthSignals
        .where((s) => s.needsAttention)
        .length;
    final pending = overview.attentionItems.length;

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'نظرة تنفيذية · $officeName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleLarge?.copyWith(
            color: onHero,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'إيراد اليوم ${money(overview.revenueToday)}'
          ' · ${_verdict(offTarget, pending)}',
          maxLines: 2,
          style: text.bodySmall?.copyWith(color: onHero.withAlpha(210)),
        ),
        // The as-of time joins the verdict line rather than claiming a third
        // row of its own — it qualifies those figures, it is not a heading.
        Text(
          'آخر تحديث ${_clock(overview.generatedAt)}',
          style: text.labelSmall?.copyWith(color: onHero.withAlpha(170)),
        ),
      ],
    );

    final actions = Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isRefreshing)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: onHero),
          ),
        if (onRefresh != null)
          IconButton(
            tooltip: 'تحديث البيانات',
            onPressed: isRefreshing ? null : onRefresh,
            icon: const Icon(DashboardIcons.refresh, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: onHero,
              backgroundColor: onHero.withAlpha(28),
            ),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        gradient: DashboardColors.heroGradient(context),
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpacing.medium),
                actions,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.medium),
              actions,
            ],
          );
        },
      ),
    );
  }

  String _verdict(int offTarget, int pending) {
    if (offTarget == 0 && pending == 0) {
      return 'كل المؤشرات ضمن المستهدف ولا شيء بانتظار قرارك';
    }
    if (offTarget == 0) return '$pending بنداً بانتظار قرارك';
    if (pending == 0) return '$offTarget مؤشراً خارج المستهدف';
    return '$offTarget مؤشراً خارج المستهدف · $pending بنداً بانتظار قرارك';
  }
}

/// Names the feeds that did not answer, so a zero on the page is always a
/// measured zero.
///
/// A quiet strip rather than an error: the rest of the page is still true, and
/// an office whose plan simply does not include the wallet should not be told
/// something is broken.
class UnavailableSourcesNotice extends StatelessWidget {
  const UnavailableSourcesNotice({super.key, required this.sources});

  final Set<BusinessDataSource> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final names = sources.map((s) => s.label).join('، ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            DashboardIcons.attention,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'لم تُحمَّل بعض المصادر: $names. الأرقام المرتبطة بها تظهر كـ «—» '
              'بدلاً من صفر.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `10:32 ص` — hand-rolled rather than `DateFormat.jm('ar')`, which needs
/// locale data initialised and would make every widget test that renders this
/// header depend on it.
String _clock(DateTime at) {
  final isMorning = at.hour < 12;
  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final minute = at.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${isMorning ? 'ص' : 'م'}';
}
