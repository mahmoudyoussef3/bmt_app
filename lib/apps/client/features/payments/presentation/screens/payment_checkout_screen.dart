import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_state.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/payment_processing_screen.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/receipt_upload_screen.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/payment_widgets.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final PaymentCheckoutData checkoutData;

  const PaymentCheckoutScreen({super.key, required this.checkoutData});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final TextEditingController _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PaymentCubit>().loadCheckout();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    context.read<PaymentCubit>().applyPromo(_promoController.text);
  }

  void _onPayPressed(PaymentCheckoutLoaded state) {
    final method = state.selectedPaymentMethod;
    final validationMessage = _validationMessage(state);
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }
    if (method == null) return;

    if (state.requiresReceipt) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptUploadScreen(
            checkoutData: widget.checkoutData,
            paymentMethod: method,
            promoCode: state.appliedPromoCode,
            promoDiscount: state.promoDiscount,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentProcessingScreen(
            checkoutData: widget.checkoutData,
            paymentMethod: method,
            promoCode: state.appliedPromoCode,
            promoDiscount: state.promoDiscount,
            simulateFailure: false,
          ),
        ),
      );
    }
  }

  String? _validationMessage(PaymentCheckoutLoaded state) {
    if (!widget.checkoutData.isReadyForPayment) {
      return 'Missing booking details: ${widget.checkoutData.missingRequiredFields.join(', ')}.';
    }
    final method = state.selectedPaymentMethod;
    if (method == null) return 'Choose a payment method to continue.';
    final total = widget.checkoutData.totalForDiscount(state.promoDiscount);
    if (method.type == PaymentMethodType.walletBalance &&
        widget.checkoutData.walletBalance < total) {
      return 'Wallet balance is not enough for this payment.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final contentPadding = width < 380 ? 16.0 : 20.0;

    return BlocBuilder<PaymentCubit, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const _PaymentLoadingScaffold();
        }
        if (state is PaymentError) {
          return _PaymentErrorScaffold(
            message: state.message,
            onRetry: () => context.read<PaymentCubit>().loadCheckout(),
          );
        }
        final checkoutState = state as PaymentCheckoutLoaded;
        final totalAmount = widget.checkoutData.totalForDiscount(
          checkoutState.promoDiscount,
        );

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ClientColors.surfaceFor(context),
                  ClientColors.surfaceMutedFor(context),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment',
                                style: ClientTypography.headingSmall(context)
                                    .copyWith(
                                      color: ClientColors.textPrimaryFor(
                                        context,
                                      ),
                                    ),
                              ),
                              Text(
                                'Review, choose method, confirm',
                                style: ClientTypography.bodySmall(context)
                                    .copyWith(
                                      color: ClientColors.textSecondaryFor(
                                        context,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ClientColors.journeyGreenLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Secure',
                            style: ClientTypography.labelSmall(context).copyWith(
                              color: ClientColors.journeyGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        contentPadding,
                        8,
                        contentPadding,
                        24,
                      ),
                      children: [
                        TripSummaryCard(data: widget.checkoutData),
                        if (!widget.checkoutData.isReadyForPayment) ...[
                          const SizedBox(height: 12),
                          _ValidationBanner(
                            missing: widget.checkoutData.missingRequiredFields,
                          ),
                        ],
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: FareBreakdownCard(
                            key: ValueKey(checkoutState.promoDiscount),
                            data: widget.checkoutData,
                            promoDiscount: checkoutState.promoDiscount,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: ClientColors.surfaceFor(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: ClientColors.borderFor(context),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose payment method',
                                style: ClientTypography.headingSmall(context)
                                    .copyWith(
                                      color: ClientColors.textPrimaryFor(
                                        context,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              if (checkoutState.methods.isEmpty)
                                const _NoPaymentMethodsState()
                              else
                                for (
                                  var index = 0;
                                  index < checkoutState.methods.length;
                                  index++
                                ) ...[
                                  PaymentMethodCard(
                                    method: checkoutState.methods[index],
                                    selected:
                                        checkoutState.selectedMethod ==
                                        checkoutState.methods[index].type,
                                    onTap: () => context
                                        .read<PaymentCubit>()
                                        .selectMethod(
                                          checkoutState.methods[index].type,
                                        ),
                                  ),
                                  if (index != checkoutState.methods.length - 1)
                                    const SizedBox(height: 10),
                                ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        PromoCodeCard(
                          controller: _promoController,
                          appliedCode: checkoutState.appliedPromoCode,
                          promoDiscount: checkoutState.promoDiscount,
                          onApply: _applyPromo,
                        ),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: ClientColors.surfaceFor(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ClientColors.borderFor(context),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Before you pay',
                                style: ClientTypography.headingSmall(context)
                                    .copyWith(
                                      color: ClientColors.textPrimaryFor(
                                        context,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Your seat is reserved only after confirmation. Please check the route, vehicle, time, seat, and total before continuing.',
                                style: ClientTypography.bodySmall(context)
                                    .copyWith(
                                      color: ClientColors.textSecondaryFor(
                                        context,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _InfoPill(label: 'Booking details checked'),
                                  _InfoPill(label: 'Secure confirmation'),
                                  _InfoPill(label: 'Support available'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    decoration: BoxDecoration(
                      color: ClientColors.surfaceFor(context).withAlpha(246),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: ClientColors.borderFor(context),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(18),
                          blurRadius: 24,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClientButton(
                            label: checkoutState.requiresReceipt
                                ? 'Continue to receipt'
                                : 'Pay Now • $totalAmount EGP',
                            onPressed: () => _onPayPressed(checkoutState),
                          ),
                          const SizedBox(height: 8),
                          if (checkoutState.selectedMethod ==
                              PaymentMethodType.walletBalance)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ClientColors.primaryLight,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Wallet: ${widget.checkoutData.walletBalance} EGP',
                                  style: ClientTypography.labelSmall(context).copyWith(
                                    color: ClientColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          else
                            Text(
                              checkoutState.requiresReceipt
                                  ? 'You will attach a receipt before confirmation.'
                                  : 'You can review the result before leaving checkout.',
                              textAlign: TextAlign.center,
                              style: ClientTypography.bodySmall(context)
                                  .copyWith(
                                    color: ClientColors.textTertiaryFor(context),
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaymentLoadingScaffold extends StatelessWidget {
  const _PaymentLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: ClientColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Preparing secure payment',
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Loading available methods and checking your booking.',
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentErrorScaffold extends StatelessWidget {
  const _PaymentErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: ClientColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: ClientColors.borderFor(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: ClientColors.journeyRed,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Payment methods unavailable',
                    style: ClientTypography.headingSmall(context).copyWith(
                      color: ClientColors.textPrimaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: ClientTypography.bodySmall(context).copyWith(
                      color: ClientColors.textSecondaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClientButton(label: 'Try again', onPressed: onRetry),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.journeyRedLight.withAlpha(70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.journeyRed.withAlpha(55)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: ClientColors.journeyRed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Complete missing details before payment: ${missing.join(', ')}.',
              style: ClientTypography.bodySmall(context).copyWith(
                color: ClientColors.onJourneyRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPaymentMethodsState extends StatelessWidget {
  const _NoPaymentMethodsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(18),
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
              'No payment methods are currently enabled. Please try again later or contact support.',
              style: ClientTypography.bodySmall(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(context).copyWith(
          color: ClientColors.textSecondaryFor(context),
        ),
      ),
    );
  }
}
