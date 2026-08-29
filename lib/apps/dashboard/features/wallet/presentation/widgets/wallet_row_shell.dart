import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// The one row shape all three محفظة العملاء tabs are read through.
///
/// The module used to draw three: a customer tile, a ledger tile and a refund
/// tile, each with its own padding, its own idea of where the money goes and
/// its own chip. Nothing about a wallet balance, a posting and a refund makes
/// them three different kinds of row — each is *one record, one amount, some
/// context and sometimes a decision* — so they are one row now, and a module
/// that reads left to right on one tab reads the same way on the next.
///
/// The lane order is fixed and carries meaning:
///
///  * **the badge** — the record's own identity mark, tinted by its state: a
///    ledger sequence number, a refund's status glyph, a customer's initial.
///  * **the body** — what it is, why, and the metadata that answers "when, by
///    whom, against what".
///  * **the amount** — always last, always the same weight, so a column of
///    money scans as a column even when the rows above and below it came from
///    different tabs.
///
/// [actions] sit under the body rather than beside the amount. A decision is
/// the row's *conclusion*, and putting it in the money lane made the refund
/// tile's buttons compete with the figure they act on.
class WalletRowShell extends StatelessWidget {
  const WalletRowShell({
    super.key,
    required this.tone,
    required this.title,
    required this.amount,
    this.leadingText,
    this.leadingIcon,
    this.chips = const [],
    this.subtitle,
    this.meta = const [],
    this.amountNote,
    this.struckThrough = false,
    this.footnote,
    this.actions = const [],
    this.onTap,
    this.selected = false,
  });

  /// The row's state colour — it tints the badge, the title and the amount, and
  /// nothing else. A fully tinted row reads as a warning even when it is just a
  /// credit.
  final Color tone;

  final String title;

  /// Already formatted and signed by the caller: `+200.00 ج.م`, `250.00 ج.م`.
  final String amount;

  /// The badge's content — one of the two, text winning if both are given.
  final String? leadingText;
  final IconData? leadingIcon;

  /// Short qualifiers that belong beside the title: a category, a source, a
  /// status. Build them with [WalletRowChip].
  final List<Widget> chips;

  /// The row's own sentence — a reason, a phone number.
  final String? subtitle;

  /// "When, by whom, against what", as icon + label pairs.
  final List<WalletRowMeta> meta;

  /// The second line of the money lane: a running balance, a status word.
  final String? amountNote;

  /// A reversed ledger entry keeps its row and strikes its numbers. Nothing is
  /// ever removed from a ledger, so nothing is ever removed from this list.
  final bool struckThrough;

  /// A full-width note under the body — the reversal notice, a batch marker.
  final Widget? footnote;

  final List<Widget> actions;

  final VoidCallback? onTap;

  /// Directory rows only: the customer whose wallet is open beside the list.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final decoration = struckThrough ? TextDecoration.lineThrough : null;

    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Badge(tone: tone, label: leadingText, icon: leadingIcon),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A Wrap, not a Row: an Arabic name beside two chips is wider
                // than the lane at the console's narrow end, and a chip that
                // ellipsises is a chip that says nothing.
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.xSmall,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: tone,
                        decoration: decoration,
                      ),
                    ),
                    ...chips,
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSpacing.medium,
                    runSpacing: 4,
                    children: [for (final item in meta) _Meta(item: item)],
                  ),
                ],
                if (footnote != null) ...[const SizedBox(height: 6), footnote!],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.xSmall,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          _Amount(
            tone: tone,
            amount: amount,
            note: amountNote,
            struckThrough: struckThrough,
          ),
        ],
      ),
    );

    final surface = Container(
      decoration: BoxDecoration(
        color: selected
            ? DashboardColors.accentFill(context).withAlpha(20)
            : Colors.transparent,
        border: BorderDirectional(
          // The selected row is marked on the reading edge, where the eye
          // starts — a tint alone is easy to miss on a long list.
          start: BorderSide(
            color: selected
                ? DashboardColors.accentFill(context)
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: body,
    );

    if (onTap == null) return surface;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: surface),
    );
  }
}

/// One "when / by whom / against what" pair on a row.
class WalletRowMeta {
  const WalletRowMeta(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// A qualifier beside a row's title — a category, a source, a status word.
class WalletRowChip extends StatelessWidget {
  const WalletRowChip({super.key, required this.label, this.tone});

  final String label;

  /// A status chip carries its tone; a neutral qualifier (a category, a source)
  /// leaves it null and renders in the well colour, so the coloured chips on a
  /// row are the ones that mean something.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final accent = tone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent == null
            ? DashboardColors.well(context)
            : accent.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(
          color: accent == null
              ? DashboardColors.border(context)
              : accent.withAlpha(110),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent ?? DashboardColors.mutedInk(context),
          fontWeight: accent == null ? null : FontWeight.bold,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.tone, this.label, this.icon});

  final Color tone;
  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = label;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.withAlpha(26),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: tone.withAlpha(70)),
      ),
      child: text != null
          ? Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: tone,
              ),
            )
          : Icon(icon, size: 20, color: tone),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.tone,
    required this.amount,
    required this.struckThrough,
    this.note,
  });

  final Color tone;
  final String amount;
  final String? note;
  final bool struckThrough;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          amount,
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: tone,
            decoration: struckThrough ? TextDecoration.lineThrough : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 2),
          Text(
            note!,
            style: text.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.item});

  final WalletRowMeta item;

  @override
  Widget build(BuildContext context) {
    final color = DashboardColors.faintInk(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          item.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
