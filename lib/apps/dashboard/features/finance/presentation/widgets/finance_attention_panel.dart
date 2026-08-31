import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/finance_attention.dart';
import 'finance_format.dart';

/// «يحتاج المتابعة» — the money waiting on a decision, and the way to it.
///
/// This is the one part of Finance that is about *doing* rather than reading,
/// and it stays inside the module's charter by never deciding anything itself:
/// each row states a count, an amount, the move to make, and opens the module
/// that owns that move. Nothing here approves, refunds or cancels.
///
/// Two rules the panel keeps:
///
///  * **It counts the whole book, not the period.** A receipt uploaded six
///    weeks ago is still undecided today. Scoping this to the period bar would
///    make work disappear by choosing a shorter window, which is the opposite
///    of what an attention list is for. The subtitle says so in words.
///  * **A clear board says so.** An empty attention panel that renders as
///    nothing is indistinguishable from one that failed to load.
///
/// The rows are one list, not six cards. Each queue used to be its own tinted,
/// bordered, separately-rounded box with its own margin, so a busy office got a
/// stack of six coloured slabs in which nothing ranked above anything else —
/// the noisiest block on the module's most-read screen, for the content that
/// most needed to be scannable. Now severity is carried by the leading glyph
/// tile and a single edge, and the rows share one frame with hairlines between
/// them, so the eye runs down the counts instead of around six borders.
class FinanceAttentionPanel extends StatelessWidget {
  const FinanceAttentionPanel({
    super.key,
    required this.attention,
    required this.onOpenModule,
  });

  final FinanceAttention attention;

  /// Opens another module by route. Null disables the hand-off, which is what
  /// the screen tests and the showcase harness pass.
  final ValueChanged<String>? onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    return DashboardPanel(
      sectionId: DashboardSectionIds.financeAttention,
      icon: DashboardIcons.attention,
      title: 'يحتاج المتابعة',
      subtitle: attention.isClear
          ? 'لا شيء معلق — كل حركة مالية وصلت لقرار'
          : 'عبر كل السجل، وليس الفترة المختارة — '
                '${FinanceFormat.count(attention.totalItems)} عنصر بقيمة '
                '${FinanceFormat.money(attention.totalAtRisk)}',
      collapsedSummary: Text(
        attention.isClear
            ? 'لا شيء معلق'
            : '${FinanceFormat.count(attention.totalItems)} عنصر • '
                  '${FinanceFormat.money(attention.totalAtRisk)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      ),
      child: attention.isClear
          ? _ClearBoard(palette: palette)
          : _QueueList(items: attention.items, onOpenModule: onOpenModule),
    );
  }
}

/// Not a decoration: an operator who sees nothing cannot tell "nothing to do"
/// from "this failed to load".
class _ClearBoard extends StatelessWidget {
  const _ClearBoard({required this.palette});

  final DashboardChartPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: palette.positive.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: palette.positive.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt_rounded, color: palette.positive, size: 20),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'لا توجد إيصالات بانتظار المراجعة، ولا طلبات استرداد معلقة، '
              'ولا مبالغ عالقة على حجوزات ملغاة.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// One frame, hairlines between rows — the console's list vocabulary.
class _QueueList extends StatelessWidget {
  const _QueueList({required this.items, required this.onOpenModule});

  final List<FinanceAttentionItem> items;
  final ValueChanged<String>? onOpenModule;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            for (final (index, item) in items.indexed) ...[
              if (index > 0)
                Divider(height: 1, color: DashboardColors.divider(context)),
              _AttentionRow(item: item, onOpenModule: onOpenModule),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item, required this.onOpenModule});

  final FinanceAttentionItem item;
  final ValueChanged<String>? onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final tone = switch (item.severity) {
      FinanceAttentionSeverity.urgent => scheme.error,
      FinanceAttentionSeverity.warning => palette.warning,
      FinanceAttentionSeverity.info => palette.neutral,
    };

    // Severity is carried by an icon and by the count's own wording as well as
    // by colour, so the row still ranks itself for an operator who cannot
    // separate the two tints.
    final glyph = switch (item.severity) {
      FinanceAttentionSeverity.urgent => Icons.priority_high_rounded,
      FinanceAttentionSeverity.warning => Icons.schedule_rounded,
      FinanceAttentionSeverity.info => Icons.info_outline_rounded,
    };

    final route = item.kind.route;
    final canOpen = route != null && onOpenModule != null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small + 2,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: tone.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(glyph, size: 16, color: tone),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.kind.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  item.kind.action,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          _Counts(item: item, tone: tone),
          const SizedBox(width: AppSpacing.small),
          Icon(
            DashboardIcons.openModule,
            size: 16,
            color: canOpen
                ? DashboardColors.mutedInk(context)
                : Colors.transparent,
          ),
        ],
      ),
    );

    return Material(
      // The row sits on the panel, not on a tint of its own — except the
      // urgent ones, which keep the faintest wash so a full board still ranks
      // at a glance rather than reading as six equal lines.
      color: item.severity == FinanceAttentionSeverity.urgent
          ? tone.withAlpha(12)
          : DashboardColors.panel(context),
      child: InkWell(
        onTap: canOpen ? () => onOpenModule!(route) : null,
        mouseCursor: canOpen
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: content,
      ),
    );
  }
}

/// The count and the money, in that order — an owner triages by "how many do I
/// have to touch" and decides urgency by "how much is in them".
class _Counts extends StatelessWidget {
  const _Counts({required this.item, required this.tone});

  final FinanceAttentionItem item;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isGap = item.kind == FinanceAttentionKind.identityBroken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isGap
              ? FinanceFormat.moneyPrecise(item.amount)
              : '${FinanceFormat.count(item.count)} ${item.kind.unit}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: tone,
          ),
        ),
        Text(
          isGap ? 'فارق المعادلة' : FinanceFormat.money(item.amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(
            color: DashboardColors.mutedInk(context),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
