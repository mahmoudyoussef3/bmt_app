import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/models/payment_models.dart';
import 'package:bmt_app/features/component/presentation/screens/payment_processing_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/receipt_upload_screen.dart';
import 'package:bmt_app/features/component/presentation/widgets/payment_widgets.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final PaymentCheckoutData checkoutData;

  const PaymentCheckoutScreen({super.key, required this.checkoutData});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  late PaymentMethodType _selectedMethod;
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _appliedPromoCode;
  int _promoDiscount = 0;

  final List<PaymentMethodData> _methods = const [
    PaymentMethodData(
      type: PaymentMethodType.creditCard,
      title: 'Credit Card',
      subtitle: 'Pay securely using your Visa or Mastercard',
      icon: Icons.credit_card_rounded,
      recommended: true,
    ),
    PaymentMethodData(
      type: PaymentMethodType.instapay,
      title: 'InstaPay',
      subtitle: 'Transfer directly using InstaPay ID & upload receipt',
      icon: Icons.account_balance_wallet_rounded,
    ),
    PaymentMethodData(
      type: PaymentMethodType.vodafoneCash,
      title: 'Mobile Wallet',
      subtitle: 'Pay via Vodafone Cash or other wallets & upload receipt',
      icon: Icons.phone_android_rounded,
    ),
    PaymentMethodData(
      type: PaymentMethodType.cashOnBoarding,
      title: 'Cash with Driver',
      subtitle: 'Pay cash directly to driver upon boarding',
      icon: Icons.payments_rounded,
    ),
    PaymentMethodData(
      type: PaymentMethodType.walletBalance,
      title: 'User Balance',
      subtitle: 'Deduct fare instantly from your account balance',
      icon: Icons.account_balance_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMethod = PaymentMethodType.creditCard;
  }

  @override
  void dispose() {
    _promoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  PaymentMethodData get _selectedPaymentMethod =>
      _methods.firstWhere((method) => method.type == _selectedMethod);

  int get _totalAmount => widget.checkoutData.totalForDiscount(_promoDiscount);

  bool get _requiresReceipt =>
      _selectedMethod == PaymentMethodType.instapay ||
      _selectedMethod == PaymentMethodType.vodafoneCash;

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    setState(() {
      _appliedPromoCode = code.isEmpty ? null : code;
      _promoDiscount = switch (code) {
        'WELCOME10' => 10,
        'MEGA20' => 20,
        _ => 0,
      };
    });
  }

  void _onPayPressed() {
    final method = _selectedPaymentMethod;
    final notes = _notesController.text.trim();

    if (_requiresReceipt) {
      // Navigate to receipt upload screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptUploadScreen(
            checkoutData: widget.checkoutData,
            paymentMethod: method,
            promoCode: _appliedPromoCode,
            promoDiscount: _promoDiscount,
            paymentNotes: notes.isEmpty ? null : notes,
          ),
        ),
      );
    } else {
      // Direct payment processing
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentProcessingScreen(
            checkoutData: widget.checkoutData,
            paymentMethod: method,
            promoCode: _appliedPromoCode,
            promoDiscount: _promoDiscount,
            simulateFailure: false,
          ),
        ),
      );
    }
  }

  void _onSimulateFailurePressed() {
    final method = _selectedPaymentMethod;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentProcessingScreen(
          checkoutData: widget.checkoutData,
          paymentMethod: method,
          promoCode: _appliedPromoCode,
          promoDiscount: _promoDiscount,
          simulateFailure: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final contentPadding = width < 380 ? 16.0 : 20.0;

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
                            'Checkout',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Premium payment experience',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: 'Secure demo',
                      color: scheme.primary.withAlpha(24),
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
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: FareBreakdownCard(
                        key: ValueKey(_promoDiscount),
                        data: widget.checkoutData,
                        promoDiscount: _promoDiscount,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppSurface(
                      radius: 24,
                      padding: const EdgeInsets.all(18),
                      color: scheme.surfaceContainerHigh,
                      border: Border.all(color: scheme.outline.withAlpha(50)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          for (
                            var index = 0;
                            index < _methods.length;
                            index++
                          ) ...[
                            PaymentMethodCard(
                              method: _methods[index],
                              selected: _selectedMethod == _methods[index].type,
                              onTap: () => setState(() {
                                _selectedMethod = _methods[index].type;
                              }),
                            ),
                            if (index != _methods.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PromoCodeCard(
                      controller: _promoController,
                      appliedCode: _appliedPromoCode,
                      promoDiscount: _promoDiscount,
                      onApply: _applyPromo,
                    ),
                    const SizedBox(height: 14),

                    // Payment Notes section
                    AppSurface(
                      radius: 24,
                      padding: const EdgeInsets.all(18),
                      color: scheme.surfaceContainerHigh,
                      border: Border.all(color: scheme.outline.withAlpha(50)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Notes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            maxLength: 100,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter any payment notes or request details here...',
                              hintStyle: TextStyle(color: Colors.grey.withAlpha(180), fontSize: 13),
                              fillColor: scheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: scheme.outline),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppSurface(
                      radius: 24,
                      padding: const EdgeInsets.all(18),
                      color: scheme.surfaceContainerHigh,
                      border: Border.all(color: scheme.outline.withAlpha(50)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Cancellation Policy',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'This is a simulated checkout. Seats are reserved only after payment success. Cancellations are allowed up to 1 hour before departure in this demo.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: const [
                              StatusChip(label: 'Instant confirmation'),
                              StatusChip(label: 'Secure demo flow'),
                              StatusChip(label: 'No real card processing'),
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
                              label: _requiresReceipt
                                  ? 'Proceed to Upload Receipt'
                                  : 'Pay Now • $_totalAmount EGP',
                              onPressed: _onPayPressed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _onSimulateFailurePressed,
                              child: const Text('Simulate failure demo'),
                            ),
                          ),
                          if (_selectedMethod ==
                              PaymentMethodType.walletBalance)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: StatusChip(
                                  label:
                                      'Wallet: ${widget.checkoutData.walletBalance} EGP',
                                  color: scheme.secondary.withAlpha(24),
                                  textColor: scheme.secondary,
                                ),
                              ),
                            ),
                        ],
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
  }
}
