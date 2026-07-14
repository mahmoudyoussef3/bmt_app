import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_method_tile.dart';

/// The list of ways to pay.
///
/// A wallet that cannot cover the fare stays visible and selectable — hiding it
/// leaves the rider wondering where their balance went. It says how short it is
/// instead, and the pay button carries the same reason.
class CheckoutMethodPicker extends StatelessWidget {
  const CheckoutMethodPicker({
    super.key,
    required this.methods,
    required this.selected,
    required this.walletBalance,
    required this.total,
    required this.onSelect,
  });

  final List<PaymentMethodData> methods;
  final PaymentMethodType? selected;
  final int walletBalance;
  final int total;
  final ValueChanged<PaymentMethodType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'How would you like to pay?',
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
        ),
        if (methods.isEmpty)
          const _NoMethods()
        else
          for (final method in methods)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CheckoutMethodTile(
                method: method,
                selected: selected == method.type,
                note: _noteFor(method.type),
                warning: _warningFor(method.type),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(method.type);
                },
              ),
            ),
      ],
    );
  }

  String? _noteFor(PaymentMethodType type) {
    if (type != PaymentMethodType.walletBalance) return null;
    return 'Balance $walletBalance EGP';
  }

  String? _warningFor(PaymentMethodType type) {
    if (type != PaymentMethodType.walletBalance) return null;
    if (walletBalance >= total) return null;
    return 'Short by ${total - walletBalance} EGP — top up or pick another '
        'method.';
  }
}

class _NoMethods extends StatelessWidget {
  const _NoMethods();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color: ClientColors.textSecondaryFor(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No payment method is switched on right now. Your seat is still '
              'held — contact support and we will take it from there.',
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }
}
