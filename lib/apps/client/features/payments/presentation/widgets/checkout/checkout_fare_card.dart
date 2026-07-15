import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// What the fare is made of, and what it comes to. Every line the rider will
/// be charged for is named here — nothing is folded into the total silently.
class CheckoutFareCard extends StatelessWidget {
  const CheckoutFareCard({
    super.key,
    required this.data,
    required this.promoDiscount,
    required this.promoField,
  });

  final PaymentCheckoutData data;
  final int promoDiscount;

  /// The promo entry, kept inside the fare card so a discount lands next to the
  /// number it changes.
  final Widget promoField;

  @override
  Widget build(BuildContext context) {
    final total = data.totalForDiscount(promoDiscount);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.payments_fareSummary,
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
          const SizedBox(height: 14),
          _FareRow(label: context.l10n.payments_ticketFare, value: data.baseFare),
          if (data.serviceFee > 0)
            _FareRow(label: context.l10n.payments_serviceFee, value: data.serviceFee),
          if (data.tax > 0) _FareRow(label: context.l10n.payments_tax, value: data.tax),
          if (promoDiscount > 0)
            _FareRow(
              label: context.l10n.payments_promoDiscount,
              value: -promoDiscount,
              valueColor: ClientColors.journeyCyan,
            ),
          const SizedBox(height: 6),
          promoField,
          Divider(height: 26, color: ClientColors.borderFor(context)),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.payments_total,
                  style: ClientTypography.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AnimatedSwitcher(
                duration: ClientMotion.base,
                child: Text(
                  FormatUtil.currency(context, total),
                  key: ValueKey(total),
                  style: ClientTypography.priceMedium(
                    context,
                  ).copyWith(color: ClientColors.primaryFor(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({required this.label, required this.value, this.valueColor});

  final String label;
  final int value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              FormatUtil.currency(context, value),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.bodySmall(context).copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? ClientColors.textPrimaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
