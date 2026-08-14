import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A label/value line item inside [TripPaymentCard] (fare, service fee, ...).
class PaymentRow extends StatelessWidget {
  const PaymentRow({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;

  /// Drops the line to metadata weight. Used for the fee and discount lines,
  /// which are zero on every booking today — they belong on the receipt, but
  /// they must not compete with the fare for the eye.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final labelColor = muted
        ? ClientColors.textTertiaryFor(context)
        : ClientColors.textSecondaryFor(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: labelColor, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: ClientTypography.bodyMedium(context).copyWith(
            fontWeight: muted ? FontWeight.w600 : FontWeight.w800,
            color: muted
                ? ClientColors.textTertiaryFor(context)
                : ClientColors.textPrimaryFor(context),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
