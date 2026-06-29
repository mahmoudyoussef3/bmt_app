import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/modules/payments/payments/domain/entities/payment_models.dart';

class TripSummaryCard extends StatelessWidget {
  final PaymentCheckoutData data;

  const TripSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [ClientColors.primary, ClientColors.primaryMuted],
                  ),
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review your booking',
                      style: ClientTypography.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confirm every detail before payment',
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.selectedSeat,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: ClientColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Route', value: data.route),
          _SummaryRow(label: 'Vehicle', value: data.vehicleNumber),
          _SummaryRow(label: 'Seat', value: 'Seat ${data.selectedSeat}'),
          _SummaryRow(label: 'Destination', value: data.destination),
          _SummaryRow(label: 'Departure', value: data.departureTime),
          _SummaryRow(label: 'Arrival', value: data.arrivalTime),
          _SummaryRow(label: 'Price', value: '${data.baseFare} EGP'),
        ],
      ),
    );
  }
}

class FareBreakdownCard extends StatelessWidget {
  final PaymentCheckoutData data;
  final int promoDiscount;
  final bool animateTotal;

  const FareBreakdownCard({
    super.key,
    required this.data,
    required this.promoDiscount,
    this.animateTotal = true,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.totalForDiscount(promoDiscount);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment total',
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _PriceRow(label: 'Trip fare', value: data.baseFare),
          if (data.serviceFee > 0)
            _PriceRow(label: 'Service fee', value: data.serviceFee),
          if (data.tax > 0) _PriceRow(label: 'Tax', value: data.tax),
          if (promoDiscount > 0)
            _PriceRow(
              label: 'Promo discount',
              value: -promoDiscount,
              valueColor: ClientColors.primary,
            ),
          Divider(height: 24, color: ClientColors.borderFor(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  '$total EGP',
                  key: ValueKey(total),
                  style: ClientTypography.priceMedium(
                    context,
                  ).copyWith(color: ClientColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PromoCodeCard extends StatelessWidget {
  final TextEditingController controller;
  final String? appliedCode;
  final int promoDiscount;
  final VoidCallback onApply;

  const PromoCodeCard({
    super.key,
    required this.controller,
    required this.appliedCode,
    required this.promoDiscount,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promo code',
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'WELCOME10'),
                ),
              ),
              const SizedBox(width: 10),
              ClientButton(label: 'Apply', onPressed: onApply, expand: false),
            ],
          ),
          const SizedBox(height: 10),
          if (appliedCode != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Container(
                key: ValueKey(appliedCode),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: promoDiscount > 0
                      ? ClientColors.journeyGreenLight
                      : ClientColors.journeyRedLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  promoDiscount > 0
                      ? '$appliedCode applied'
                      : '$appliedCode not valid',
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: promoDiscount > 0
                        ? ClientColors.journeyGreen
                        : ClientColors.journeyRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethodData method;
  final bool selected;
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.01 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? ClientColors.primaryLight
              : ClientColors.surfaceMutedFor(context),
          border: Border.all(
            color: selected
                ? ClientColors.primary
                : ClientColors.borderFor(context),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ClientColors.primaryLight,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? ClientColors.primary
                          : ClientColors.surfaceSubtleFor(context),
                    ),
                    child: Icon(
                      _paymentMethodIcon(method.type),
                      color: selected
                          ? Colors.white
                          : ClientColors.textSecondaryFor(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                method.title,
                                style: ClientTypography.bodyMedium(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (method.recommended)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: ClientColors.journeyGreenLight,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Recommended',
                                  style: ClientTypography.labelSmall(context)
                                      .copyWith(
                                        color: ClientColors.journeyGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method.subtitle,
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _paymentMethodNextStep(method.type),
                          style: ClientTypography.labelSmall(context).copyWith(
                            color: ClientColors.textTertiaryFor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? ClientColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? ClientColors.primary
                            : ClientColors.borderFor(context),
                        width: 1.4,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _paymentMethodNextStep(PaymentMethodType type) {
  return switch (type) {
    PaymentMethodType.creditCard => 'Next: secure card authorization',
    PaymentMethodType.instapay => 'Next: transfer details and receipt',
    PaymentMethodType.vodafoneCash => 'Next: wallet transfer and receipt',
    PaymentMethodType.cashOnBoarding => 'Next: reserve now and pay on boarding',
    PaymentMethodType.walletBalance => 'Next: instant wallet deduction',
  };
}

IconData _paymentMethodIcon(PaymentMethodType type) {
  return switch (type) {
    PaymentMethodType.creditCard => Icons.credit_card_rounded,
    PaymentMethodType.instapay => Icons.account_balance_wallet_rounded,
    PaymentMethodType.vodafoneCash => Icons.phone_android_rounded,
    PaymentMethodType.cashOnBoarding => Icons.payments_rounded,
    PaymentMethodType.walletBalance => Icons.account_balance_rounded,
  };
}

// Private row widgets shared by the cards above

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = ClientTypography.bodySmall(
      context,
    ).copyWith(color: ClientColors.textSecondaryFor(context));
    final valueStyle = ClientTypography.bodySmall(
      context,
    ).copyWith(fontWeight: FontWeight.w700);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackValue = constraints.maxWidth < 330 || value.length > 34;
        if (stackValue) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 92, child: Text(label, style: labelStyle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.valueColor});
  final String label;
  final num value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              '${value > 0 ? '+' : ''}$value EGP',
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(fontWeight: FontWeight.w700, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
