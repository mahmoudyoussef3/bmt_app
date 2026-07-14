import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_state.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/payment_processing_screen.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/receipt_upload_screen.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_assurance.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_fare_card.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_header.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_method_picker.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_notice.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_pay_bar.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_progress.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_promo_field.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_skeleton.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_ticket_card.dart';

/// The rider reviews the ticket they are buying, picks how to pay, and pays.
///
/// Everything that could stop the payment — a missing seat, an empty wallet, no
/// method chosen — is surfaced on the pay bar before it is pressed, so the
/// button is never a coin toss.
class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key, required this.checkoutData});

  final PaymentCheckoutData checkoutData;

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

  void _pay(PaymentCheckoutLoaded state) {
    final method = state.selectedPaymentMethod;
    if (method == null) return;

    HapticFeedback.mediumImpact();
    final data = widget.checkoutData;
    final promoCode = state.promoStatus == PromoStatus.applied
        ? state.promoCode
        : null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => state.requiresReceipt
            ? ReceiptUploadScreen(
                checkoutData: data,
                paymentMethod: method,
                promoCode: promoCode,
                promoDiscount: state.promoDiscount,
              )
            : PaymentProcessingScreen(
                checkoutData: data,
                paymentMethod: method,
                promoCode: promoCode,
                promoDiscount: state.promoDiscount,
              ),
      ),
    );
  }

  /// Why the rider cannot pay yet — `null` once they can.
  String? _blockedReason(PaymentCheckoutLoaded state, int total) {
    final data = widget.checkoutData;
    if (!data.isReadyForPayment) {
      return 'Some booking details are missing.';
    }
    final method = state.selectedPaymentMethod;
    if (method == null) return 'Choose a payment method to continue.';
    if (method.type == PaymentMethodType.walletBalance &&
        data.walletBalance < total) {
      return 'Your wallet is ${total - data.walletBalance} EGP short of this '
          'fare.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentCubit, PaymentState>(
      builder: (context, state) {
        return switch (state) {
          PaymentLoading() => const _Shell(child: CheckoutSkeleton()),
          PaymentError(:final message) => _Shell(
            child: ClientErrorCard.fullScreen(
              message: message,
              onRetry: () => context.read<PaymentCubit>().loadCheckout(),
            ),
          ),
          PaymentCheckoutLoaded() => _buildCheckout(context, state),
        };
      },
    );
  }

  Widget _buildCheckout(BuildContext context, PaymentCheckoutLoaded state) {
    final data = widget.checkoutData;
    final total = data.totalForDiscount(state.promoDiscount);
    final blockedReason = _blockedReason(state, total);
    final cubit = context.read<PaymentCubit>();
    final padding = MediaQuery.sizeOf(context).width < 380 ? 16.0 : 20.0;

    return _Shell(
      bottomBar: CheckoutPayBar(
        total: total,
        subtotal: data.subtotal,
        label: state.requiresReceipt ? 'Continue' : 'Pay now',
        blockedReason: blockedReason,
        onPay: blockedReason == null ? () => _pay(state) : null,
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(padding, 4, padding, 24),
        children: [
          if (!data.isReadyForPayment) ...[
            CheckoutNotice(
              missing: data.missingRequiredFields,
              onFix: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 14),
          ],
          CheckoutTicketCard(data: data),
          const SizedBox(height: 16),
          CheckoutFareCard(
            data: data,
            promoDiscount: state.promoDiscount,
            promoField: CheckoutPromoField(
              controller: _promoController,
              status: state.promoStatus,
              code: state.promoCode,
              discount: state.promoDiscount,
              onApply: () => cubit.applyPromo(_promoController.text),
              onClear: cubit.clearPromo,
            ),
          ),
          const SizedBox(height: 22),
          CheckoutMethodPicker(
            methods: state.methods,
            selected: state.selectedMethod,
            walletBalance: data.walletBalance,
            total: total,
            onSelect: cubit.selectMethod,
          ),
          const SizedBox(height: 16),
          CheckoutAssurance(requiresReceipt: state.requiresReceipt),
        ],
      ),
    );
  }
}

/// The frame every checkout state shares: exit, progress, content, and — once
/// there is something to pay for — the pay bar.
class _Shell extends StatelessWidget {
  const _Shell({required this.child, this.bottomBar});

  final Widget child;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CheckoutHeader(onBack: () => Navigator.of(context).maybePop()),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: CheckoutProgress(),
            ),
            Expanded(child: child),
            ?bottomBar,
          ],
        ),
      ),
    );
  }
}
