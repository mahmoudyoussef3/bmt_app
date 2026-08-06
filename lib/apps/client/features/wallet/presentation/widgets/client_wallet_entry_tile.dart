import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

import '../../domain/entities/client_wallet.dart';

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
                  entry.kind.label,
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
                  _date(entry.createdAt),
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
                // U+2212, not a hyphen: at this size in an RTL column a hyphen
                // is easy to miss, and "was that taken from me?" is the one
                // question this string exists to answer.
                '${entry.isCredit ? '+' : '−'}${entry.amount.abs().toStringAsFixed(2)}',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: tint,
                  decoration: entry.isReversed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              Text(
                'الرصيد ${entry.balanceAfter.toStringAsFixed(2)}',
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

  String _date(DateTime value) =>
      '${value.year}/${_two(value.month)}/${_two(value.day)} — '
      '${_two(value.hour)}:${_two(value.minute)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
