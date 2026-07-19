import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One "label … value" line in the redemption confirmation's balance summary.
class RedeemBalanceRow extends StatelessWidget {
  const RedeemBalanceRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;

  /// Highlights the resulting balance, the number the rider actually decides on.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        Text(
          value,
          style: ClientTypography.labelMedium(context).copyWith(
            color: emphasize ? ClientColors.primaryFor(context) : null,
          ),
        ),
      ],
    );
  }
}
