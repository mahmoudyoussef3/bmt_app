import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import 'wallet_format.dart';
import 'wallet_row_shell.dart';

/// One line of the ledger, used by both the customer's history and the
/// office-wide activity list.
///
/// Built on [WalletRowShell] so a posting read in the detail pane and the same
/// posting read on الحركات المالية are the same row, and so it sits in a list
/// beside a customer and a refund without changing shape.
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
    final tint = WalletFormat.entryColor(entry, context);

    return WalletRowShell(
      tone: tint,
      // The gapless per-wallet sequence exists in the schema for tamper
      // detection; putting it in the badge turns that into something an
      // operator can actually notice.
      leadingText: '#${entry.seq}',
      title: entry.kind.label,
      chips: [
        WalletRowChip(label: entry.categoryLabel),
        if (entry.source != WalletSource.dashboard)
          WalletRowChip(label: entry.source.label),
      ],
      subtitle: entry.reason,
      meta: [
        WalletRowMeta(
          Icons.schedule_rounded,
          WalletFormat.dateTime(entry.createdAt),
        ),
        WalletRowMeta(Icons.person_outline_rounded, entry.performedByName),
        if (showCustomer && entry.clientName != null)
          WalletRowMeta(Icons.badge_outlined, entry.clientName!),
        if (entry.bookingNumber != null)
          WalletRowMeta(
            Icons.confirmation_number_outlined,
            'حجز #${entry.bookingNumber}',
          ),
      ],
      amount: WalletFormat.signed(entry.amount),
      amountNote: 'الرصيد ${WalletFormat.money(entry.balanceAfter)}',
      struckThrough: entry.isReversed,
      footnote: entry.isReversed
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.undo_rounded, size: 14, color: scheme.error),
                const SizedBox(width: 4),
                Text(
                  'تم عكس هذه العملية — السجل محفوظ للمراجعة',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: scheme.error),
                ),
              ],
            )
          : null,
      actions: [
        if (onReverse != null)
          TextButton.icon(
            onPressed: onReverse,
            icon: const Icon(Icons.undo_rounded, size: 16),
            label: const Text('عكس'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
            ),
          ),
      ],
    );
  }
}
