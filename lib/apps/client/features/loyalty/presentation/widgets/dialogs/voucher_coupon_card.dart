import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../../domain/entities/redeemable_reward.dart';

/// The unlocked voucher: headline value, reward name and the coupon code.
class VoucherCouponCard extends StatelessWidget {
  const VoucherCouponCard({super.key, required this.reward});

  final RedeemableReward reward;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          Text(
            reward.valueLabel,
            textAlign: TextAlign.center,
            style: ClientTypography.headingMedium(
              context,
            ).copyWith(color: primary),
          ),
          const SizedBox(height: ClientSpacing.xxs),
          Text(
            reward.title,
            textAlign: TextAlign.center,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const Divider(height: ClientSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClientSpacing.sm,
              vertical: ClientSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: primary.withAlpha(30),
              borderRadius: BorderRadius.circular(ClientRadius.xs),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reward.couponCode,
                  style: ClientTypography.labelLarge(
                    context,
                  ).copyWith(color: primary, letterSpacing: 1),
                ),
                const SizedBox(width: ClientSpacing.xs),
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: ClientColors.textTertiaryFor(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
