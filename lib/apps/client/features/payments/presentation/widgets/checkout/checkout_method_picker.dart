import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_method_tile.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

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
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
          child: Text(
            context.l10n.payments_howToPay,
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
                note: _noteFor(context, method.type),
                warning: _warningFor(context, method.type),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(method.type);
                },
              ),
            ),
      ],
    );
  }

  String? _noteFor(BuildContext context, PaymentMethodType type) {
    if (type != PaymentMethodType.walletBalance) return null;
    return context.l10n.payments_balanceAmount(
      FormatUtil.currency(context, walletBalance),
    );
  }

  String? _warningFor(BuildContext context, PaymentMethodType type) {
    if (type != PaymentMethodType.walletBalance) return null;
    if (walletBalance >= total) return null;
    return context.l10n.payments_shortByAmount(
      FormatUtil.currency(context, total - walletBalance),
    );
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
              context.l10n.payments_noMethodsAvailable,
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
