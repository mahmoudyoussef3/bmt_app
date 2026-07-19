import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/points_transaction.dart';
import '../loyalty_empty_state.dart';
import '../loyalty_section_label.dart';
import 'loyalty_transaction_tile.dart';

/// The points ledger.
class LoyaltyHistoryView extends StatelessWidget {
  const LoyaltyHistoryView({super.key, required this.transactions});

  final List<PointsTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.lg,
        ClientSpacing.md,
        ClientSpacing.lg,
        ClientSpacing.xl,
      ),
      children: [
        LoyaltySectionLabel(
          l10n.loyalty_transactionLedger,
          trailing: Text(
            l10n.loyalty_activeLogs,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ),
        const SizedBox(height: ClientSpacing.sm),
        if (transactions.isEmpty)
          LoyaltyEmptyState(
            icon: Icons.receipt_long_rounded,
            title: l10n.loyalty_historyEmptyTitle,
            body: l10n.loyalty_historyEmptyBody,
          )
        else
          ...transactions.map(
            (transaction) => LoyaltyTransactionTile(transaction: transaction),
          ),
      ],
    );
  }
}
