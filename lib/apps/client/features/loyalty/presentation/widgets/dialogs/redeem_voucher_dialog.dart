import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/redeemable_reward.dart';
import 'voucher_coupon_card.dart';

/// Presents the coupon unlocked by redeeming [reward].
Future<void> showRedeemVoucherDialog(
  BuildContext context,
  RedeemableReward reward,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _RedeemVoucherDialog(reward: reward),
  );
}

class _RedeemVoucherDialog extends StatelessWidget {
  const _RedeemVoucherDialog({required this.reward});

  final RedeemableReward reward;

  /// Copies the code and closes. The messenger is resolved *before* the pop —
  /// reading it from a defunct dialog context afterwards is what made the
  /// confirmation snack unreliable.
  Future<void> _copyAndClose(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.loyalty_voucherCopiedSnack;

    await Clipboard.setData(ClipboardData(text: reward.couponCode));
    if (context.mounted) Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ClientColors.journeyCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClientRadius.lg),
      ),
      title: Text(
        l10n.loyalty_voucherUnlocked,
        textAlign: TextAlign.center,
        style: ClientTypography.headingSmall(context),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            color: ClientColors.journeyAmber,
            size: 54,
          ),
          const SizedBox(height: ClientSpacing.sm),
          Text(
            l10n.loyalty_couponGeneratedBody,
            textAlign: TextAlign.center,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: ClientSpacing.md),
          VoucherCouponCard(reward: reward),
        ],
      ),
      actions: [
        ClientButton(
          label: l10n.loyalty_copyAndClose,
          onPressed: () => _copyAndClose(context),
        ),
      ],
    );
  }
}
