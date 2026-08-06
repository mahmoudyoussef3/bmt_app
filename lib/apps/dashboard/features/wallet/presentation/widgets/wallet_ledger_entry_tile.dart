import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import 'wallet_format.dart';

/// One line of the ledger, used by both the customer's history and the
/// office-wide activity list.
///
/// Three things are non-negotiable on this row, and each answers a question the
/// operator is actually being asked:
///
///  * **the sequence number** — "was anything deleted?" A gap is visible here.
///  * **the running balance** — "why is my balance this?" An amount alone
///    cannot answer that; the position after the entry can.
///  * **the reversal link** — a reversed entry stays visible, struck through,
///    pointing at what corrected it. Nothing disappears from a ledger.
class WalletLedgerEntryTile extends StatelessWidget {
  const WalletLedgerEntryTile({
    super.key,
    required this.entry,
    this.showCustomer = false,
    this.onReverse,
  });

  final WalletTransaction entry;

  /// True on the office-wide ledger, where the customer is a column rather than
  /// the page.
  final bool showCustomer;

  /// Null when the operator may not reverse, or when this entry cannot be
  /// reversed (a reversal, or one already reversed).
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tint = WalletFormat.entryColor(entry, context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeqBadge(seq: entry.seq, tint: tint),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.kind.label,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tint,
                          decoration: entry.isReversed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    _Chip(label: entry.categoryLabel),
                    if (entry.source != WalletSource.dashboard) ...[
                      const SizedBox(width: 4),
                      _Chip(label: entry.source.label),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.reason,
                  style: text.bodySmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: AppSpacing.medium,
                  runSpacing: 4,
                  children: [
                    _Meta(
                      icon: Icons.schedule_rounded,
                      label: WalletFormat.dateTime(entry.createdAt),
                    ),
                    _Meta(
                      icon: Icons.person_outline_rounded,
                      label: entry.performedByName,
                    ),
                    if (showCustomer && entry.clientName != null)
                      _Meta(
                        icon: Icons.badge_outlined,
                        label: entry.clientName!,
                      ),
                    if (entry.bookingNumber != null)
                      _Meta(
                        icon: Icons.confirmation_number_outlined,
                        label: 'حجز #${entry.bookingNumber}',
                      ),
                  ],
                ),
                if (entry.isReversed) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.undo_rounded, size: 14, color: scheme.error),
                      const SizedBox(width: 4),
                      Text(
                        'تم عكس هذه العملية — السجل محفوظ للمراجعة',
                        style: text.labelSmall?.copyWith(color: scheme.error),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                WalletFormat.signed(entry.amount),
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: tint,
                  decoration: entry.isReversed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'الرصيد ${WalletFormat.money(entry.balanceAfter)}',
                style: text.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
              if (onReverse != null) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: onReverse,
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('عكس'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The gapless per-wallet sequence, rendered as `#12`. It exists in the schema
/// for tamper detection; showing it turns that into something an operator can
/// actually notice.
class _SeqBadge extends StatelessWidget {
  const _SeqBadge({required this.seq, required this.tint});

  final int seq;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withAlpha(26),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: tint.withAlpha(70)),
      ),
      child: Text(
        '#$seq',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: tint,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = DashboardColors.faintInk(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
