import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/client_wallet.dart';
import 'client_wallet_kind_label.dart';

/// One line of the rider's history.
///
/// The running balance sits under the amount for the same reason it does on the
/// operator's screen: the question this list answers is "why is my balance
/// this", and an amount on its own cannot answer it.
///
/// A reversed entry is struck through and stays. Nothing is removed from a
/// ledger — a line that quietly vanished would look like a correction being
/// hidden, which is the opposite of what a correction is for.
class ClientWalletEntryTile extends StatelessWidget {
  const ClientWalletEntryTile({super.key, required this.entry});

  final ClientWalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final tint = entry.isReversed
        ? scheme.onSurfaceVariant
        : entry.isCredit
        ? scheme.primary
        : scheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClientSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry.isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 18,
            color: tint,
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.kind.localizedLabel(context),
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: entry.isReversed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                Text(
                  entry.reason,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${FormatUtil.date(context, entry.createdAt)}'
                  ' — ${FormatUtil.time(context, entry.createdAt)}',
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ClientSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                
                '${entry.isCredit ? '+' : '−'}'
                '${FormatUtil.currency(context, entry.amount.abs())}',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: tint,
                  decoration: entry.isReversed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              Text(
                context.l10n.wallet_balanceAfter(
                  FormatUtil.currency(context, entry.balanceAfter),
                ),
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
