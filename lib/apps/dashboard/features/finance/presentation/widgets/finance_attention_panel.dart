import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;

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
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      child: attention.isClear
          ? _ClearBoard(palette: palette)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in attention.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.small),
                    child: _AttentionRow(
                      item: item,
                      onOpenModule: onOpenModule,
                    ),
                  ),
              ],
            ),
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

    // Severity is carried by an icon and by the count chip's own wording as
    // well as by colour, so the row still ranks itself for an operator who
    // cannot separate the two tints.
    final glyph = switch (item.severity) {
      FinanceAttentionSeverity.urgent => Icons.priority_high_rounded,
      FinanceAttentionSeverity.warning => Icons.schedule_rounded,
      FinanceAttentionSeverity.info => Icons.info_outline_rounded,
    };

    final route = item.kind.route;
    final canOpen = route != null && onOpenModule != null;

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: tone.withAlpha(28),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Icon(glyph, size: 18, color: tone),
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
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.kind.action,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          _Counts(item: item, tone: tone),
          if (canOpen) ...[
            const SizedBox(width: AppSpacing.small),
            Icon(
              DashboardIcons.openModule,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    return Material(
      color: tone.withAlpha(14),
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InkWell(
        onTap: canOpen ? () => onOpenModule!(route) : null,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        mouseCursor: canOpen
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border.all(color: tone.withAlpha(60)),
          ),
          child: content,
        ),
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
    final scheme = Theme.of(context).colorScheme;
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
          style: text.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: tone,
          ),
        ),
        Text(
          isGap ? 'فارق المعادلة' : FinanceFormat.money(item.amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
