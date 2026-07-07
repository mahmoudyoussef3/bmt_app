import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A label/value line item inside [TripPaymentCard] (fare, service fee, ...).
class PaymentRow extends StatelessWidget {
  const PaymentRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ClientTypography.bodyMedium(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: ClientTypography.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w900,
            color: ClientColors.textPrimaryFor(context),
          ),
        ),
      ],
    );
  }
}
