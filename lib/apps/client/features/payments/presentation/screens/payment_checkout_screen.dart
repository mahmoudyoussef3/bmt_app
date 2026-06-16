import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
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
    final scheme = Theme.of(context).colorScheme;
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
                colors: [scheme.surface, scheme.surfaceContainerLowest],
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'Review, choose method, confirm',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const StatusChip(label: 'Secure'),
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
                        AppSurface(
                          radius: 24,
                          padding: const EdgeInsets.all(18),
                          color: scheme.surfaceContainerHigh,
                          border: Border.all(
                            color: scheme.outline.withAlpha(50),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose payment method',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
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
                        AppSurface(
                          radius: 20,
                          padding: const EdgeInsets.all(18),
                          color: scheme.surfaceContainerHigh,
                          border: Border.all(
                            color: scheme.outline.withAlpha(50),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Before you pay',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Your seat is reserved only after confirmation. Please check the route, vehicle, time, seat, and total before continuing.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: const [
                                  StatusChip(label: 'Booking details checked'),
                                  StatusChip(label: 'Secure confirmation'),
                                  StatusChip(label: 'Support available'),
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
                      color: scheme.surface.withAlpha(246),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border(
                        top: BorderSide(color: scheme.outline.withAlpha(40)),
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
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: checkoutState.requiresReceipt
                                      ? 'Continue to receipt'
                                      : 'Pay Now • $totalAmount EGP',
                                  onPressed: () => _onPayPressed(checkoutState),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (checkoutState.selectedMethod ==
                              PaymentMethodType.walletBalance)
                            Align(
                              alignment: Alignment.centerRight,
                              child: StatusChip(
                                label:
                                    'Wallet: ${widget.checkoutData.walletBalance} EGP',
                                color: scheme.secondary.withAlpha(24),
                                textColor: scheme.secondary,
                              ),
                            )
                          else
                            Text(
                              checkoutState.requiresReceipt
                                  ? 'You will attach a receipt before confirmation.'
                                  : 'You can review the result before leaving checkout.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurface.withAlpha(145),
                                    fontWeight: FontWeight.w600,
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AppSurface(
            radius: 22,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Preparing secure payment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Loading available methods and checking your booking.',
                  style: Theme.of(context).textTheme.bodySmall,
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AppSurface(
              radius: 22,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, color: scheme.error),
                  const SizedBox(height: 12),
                  Text(
                    'Payment methods unavailable',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  AppButton(label: 'Try again', onPressed: onRetry),
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
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: scheme.errorContainer.withAlpha(70),
      border: Border.all(color: scheme.error.withAlpha(55)),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Complete missing details before payment: ${missing.join(', ')}.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withAlpha(55)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No payment methods are currently enabled. Please try again later or contact support.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
