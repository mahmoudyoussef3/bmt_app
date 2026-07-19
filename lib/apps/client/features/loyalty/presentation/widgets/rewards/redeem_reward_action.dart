import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/redeemable_reward.dart';
import '../../cubit/loyalty_cubit.dart';
import '../dialogs/redeem_confirm_dialog.dart';
import '../dialogs/redeem_voucher_dialog.dart';
import '../loyalty_celebration_host.dart';

/// Confirm → redeem → celebrate, or report the failure.
///
/// The celebration and the voucher only fire once the redemption has actually
/// persisted. Firing them optimistically meant a rider whose redemption failed
/// still got confetti and a coupon code that was never issued.
Future<void> redeemRewardFlow(
  BuildContext context, {
  required RedeemableReward reward,
  required int balance,
}) async {
  final confirmed = await showRedeemConfirmDialog(
    context,
    reward: reward,
    balance: balance,
  );
  if (!confirmed || !context.mounted) return;

  final failure = await context.read<LoyaltyCubit>().redeem(reward);
  if (!context.mounted) return;

  if (failure != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.loyalty_redeemFailed(failure)),
        backgroundColor: ClientColors.journeyRed,
      ),
    );
    return;
  }

  LoyaltyCelebrationHost.celebrate(context);
  await showRedeemVoucherDialog(context, reward);
}
