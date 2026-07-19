import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/redeemable_reward.dart';
import 'redeem_balance_row.dart';
import 'redeem_reward_summary.dart';

/// Asks the rider to confirm spending points on [reward].
///
/// Resolves `true` only when they confirm, so the caller decides what to do
/// next rather than the dialog reaching back into a cubit.
Future<bool> showRedeemConfirmDialog(
  BuildContext context, {
  required RedeemableReward reward,
  required int balance,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _RedeemConfirmDialog(reward: reward, balance: balance),
  );
  return confirmed ?? false;
}

class _RedeemConfirmDialog extends StatelessWidget {
  const _RedeemConfirmDialog({required this.reward, required this.balance});

  final RedeemableReward reward;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unit = l10n.loyalty_ptsUnit;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClientRadius.lg),
      ),
      title: Text(
        l10n.loyalty_confirmRedemptionTitle,
        style: ClientTypography.headingSmall(context),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.loyalty_confirmRedemptionBody,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: ClientSpacing.sm),
          RedeemRewardSummary(reward: reward),
          const SizedBox(height: ClientSpacing.sm),
          RedeemBalanceRow(
            label: l10n.loyalty_currentBalance,
            value: '$balance $unit',
          ),
          RedeemBalanceRow(
            label: l10n.loyalty_balanceAfterRedemption,
            value: '${balance - reward.pointsCost} $unit',
            emphasize: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.common_cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.loyalty_redeemNow),
        ),
      ],
    );
  }
}
