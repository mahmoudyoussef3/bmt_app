import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';

class TripSummaryCard extends StatelessWidget {
  final PaymentCheckoutData data;

  const TripSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      radius: 24,
      padding: const EdgeInsets.all(18),
      color: scheme.surfaceContainerHigh,
      border: Border.all(color: scheme.outline.withAlpha(50)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.secondary],
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
                      'Trip Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Secure checkout for your shuttle ride',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: data.selectedSeat,
                color: scheme.primary.withAlpha(24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Pickup', value: data.pickupPoint),
          _SummaryRow(label: 'Destination', value: data.destination),
          _SummaryRow(label: 'Vehicle', value: data.vehicleNumber),
          _SummaryRow(label: 'Departure', value: data.departureTime),
          _SummaryRow(label: 'Arrival', value: data.arrivalTime),
          _SummaryRow(label: 'Seat', value: 'Seat ${data.selectedSeat}'),
          _SummaryRow(label: 'Driver', value: data.driverName),
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
    final scheme = Theme.of(context).colorScheme;
    final total = data.totalForDiscount(promoDiscount);
    return AppSurface(
      radius: 24,
      padding: const EdgeInsets.all(18),
      color: scheme.surfaceContainerHighest,
      border: Border.all(color: scheme.outline.withAlpha(50)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Breakdown',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _PriceRow(label: 'Base fare', value: data.baseFare),
          _PriceRow(label: 'Service fee', value: data.serviceFee),
          _PriceRow(label: 'Tax', value: data.tax),
          if (promoDiscount > 0)
            _PriceRow(
              label: 'Promo discount',
              value: -promoDiscount,
              valueColor: scheme.primary,
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  '$total EGP',
                  key: ValueKey(total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
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
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      radius: 24,
      padding: const EdgeInsets.all(18),
      color: scheme.surfaceContainerHigh,
      border: Border.all(color: scheme.outline.withAlpha(50)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promo Code',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
              AppButton(label: 'Apply', onPressed: onApply),
            ],
          ),
          const SizedBox(height: 10),
          if (appliedCode != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: StatusChip(
                key: ValueKey(appliedCode),
                label: promoDiscount > 0
                    ? '$appliedCode applied'
                    : '$appliedCode not valid',
                color: promoDiscount > 0
                    ? scheme.primary.withAlpha(24)
                    : scheme.error.withAlpha(20),
                textColor: promoDiscount > 0 ? scheme.primary : scheme.error,
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
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: selected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? scheme.primary.withAlpha(18)
              : scheme.surfaceContainerHighest,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline.withAlpha(55),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withAlpha(20),
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
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: selected
                            ? [scheme.primary, scheme.secondary]
                            : [
                                scheme.surfaceContainerHighest,
                                scheme.surfaceContainerLow,
                              ],
                      ),
                    ),
                    child: Icon(
                      _paymentMethodIcon(method.type),
                      color: selected ? Colors.white : scheme.onSurface,
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
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (method.recommended)
                              StatusChip(
                                label: 'Recommended',
                                color: scheme.secondary.withAlpha(24),
                                textColor: scheme.secondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method.subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
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
                      color: selected ? scheme.primary : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outline.withAlpha(90),
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

IconData _paymentMethodIcon(PaymentMethodType type) {
  return switch (type) {
    PaymentMethodType.creditCard => Icons.credit_card_rounded,
    PaymentMethodType.instapay => Icons.account_balance_wallet_rounded,
    PaymentMethodType.vodafoneCash => Icons.phone_android_rounded,
    PaymentMethodType.cashOnBoarding => Icons.payments_rounded,
    PaymentMethodType.walletBalance => Icons.account_balance_rounded,
  };
}

class PaymentStatusView extends StatelessWidget {
  final bool success;
  final bool failure;
  final String title;
  final String subtitle;
  final String detailLabel;
  final String detailValue;
  final String transactionId;
  final String? secondaryDetailLabel;
  final String? secondaryDetailValue;

  const PaymentStatusView({
    super.key,
    required this.success,
    required this.failure,
    required this.title,
    required this.subtitle,
    required this.detailLabel,
    required this.detailValue,
    required this.transactionId,
    this.secondaryDetailLabel,
    this.secondaryDetailValue,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = failure ? scheme.error : scheme.primary;
    return AppSurface(
      radius: 28,
      padding: const EdgeInsets.all(20),
      color: scheme.surfaceContainerHighest,
      border: Border.all(color: accent.withAlpha(40)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 240),
            scale: success || failure ? 1.0 : 0.98,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: failure
                      ? [scheme.error, scheme.error.withAlpha(180)]
                      : [scheme.primary, scheme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withAlpha(35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                failure ? Icons.close_rounded : Icons.check_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              title,
              key: ValueKey(title),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: scheme.surfaceContainerLow,
              border: Border.all(color: scheme.outline.withAlpha(40)),
            ),
            child: Column(
              children: [
                _PaymentStatusRow(label: detailLabel, value: detailValue),
                const SizedBox(height: 10),
                _PaymentStatusRow(
                  label: 'Transaction ID',
                  value: transactionId,
                ),
                if (secondaryDetailLabel != null &&
                    secondaryDetailValue != null) ...[
                  const SizedBox(height: 10),
                  _PaymentStatusRow(
                    label: secondaryDetailLabel!,
                    value: secondaryDetailValue!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionSummaryCard extends StatelessWidget {
  final PaymentResultData data;

  const TransactionSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      radius: 24,
      padding: const EdgeInsets.all(18),
      color: scheme.surfaceContainerHigh,
      border: Border.all(color: scheme.outline.withAlpha(50)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Booking reference', value: data.bookingReference),
          _SummaryRow(label: 'Payment method', value: data.paymentMethodTitle),
          _SummaryRow(label: 'Promo code', value: data.promoCode ?? 'None'),
          _SummaryRow(label: 'Amount paid', value: '${data.paidAmount} EGP'),
          if (data.fromWallet && data.remainingWalletBalance != null)
            _SummaryRow(
              label: 'Wallet remaining',
              value: '${data.remainingWalletBalance} EGP',
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final int value;
  final Color? valueColor;

  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            '${value < 0 ? '-' : ''}${value.abs()} EGP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentStatusRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
