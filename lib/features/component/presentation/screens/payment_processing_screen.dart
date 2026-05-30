import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/models/payment_models.dart';
import 'package:bmt_app/features/component/presentation/screens/booking_confirmation_screen.dart';
import 'package:bmt_app/features/component/presentation/widgets/payment_widgets.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final PaymentCheckoutData checkoutData;
  final PaymentMethodData paymentMethod;
  final String? promoCode;
  final int promoDiscount;
  final bool simulateFailure;

  const PaymentProcessingScreen({
    super.key,
    required this.checkoutData,
    required this.paymentMethod,
    required this.promoCode,
    required this.promoDiscount,
    required this.simulateFailure,
  });

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _checkController;
  bool _loading = true;
  bool _failed = false;
  late final String _transactionId;
  late final String _bookingReference;
  PaymentResultData? _result;

  @override
  void initState() {
    super.initState();
    _transactionId = _generateId(prefix: 'TXN');
    _bookingReference = _generateId(prefix: 'MGT');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final shouldFail =
          widget.simulateFailure ||
          (widget.paymentMethod.type == PaymentMethodType.cashOnBoarding &&
              widget.checkoutData.totalForDiscount(widget.promoDiscount) > 90);

      if (shouldFail) {
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }

      final total = widget.checkoutData.totalForDiscount(widget.promoDiscount);
      final remaining =
          widget.paymentMethod.type == PaymentMethodType.walletBalance
          ? widget.checkoutData.remainingWalletAfterPayment(total)
          : null;
      setState(() {
        _loading = false;
        _result = PaymentResultData(
          transactionId: _transactionId,
          bookingReference: _bookingReference,
          paidAmount: total,
          paymentMethodTitle: widget.paymentMethod.title,
          promoCode: widget.promoCode,
          promoDiscount: widget.promoDiscount,
          fromWallet:
              widget.paymentMethod.type == PaymentMethodType.walletBalance,
          remainingWalletBalance: remaining,
        );
      });
      _checkController.forward();
    });
  }

  String _generateId({required String prefix}) {
    final rng = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final body = List.generate(
      5,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    return '$prefix-2026-$body';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = widget.checkoutData.totalForDiscount(widget.promoDiscount);

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
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: _loading
                        ? _processingView(context, total)
                        : _failed
                        ? _failureView(context)
                        : _successView(context, total),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _processingView(BuildContext context, int total) {
    return _stateShell(
      key: const ValueKey('processing'),
      child: AppSurface(
        radius: 28,
        padding: const EdgeInsets.all(20),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return AnimatedScale(
                  scale: 0.95 + (_pulseController.value * 0.08),
                  duration: const Duration(milliseconds: 120),
                  child: AnimatedOpacity(
                    opacity: 0.55 + (_pulseController.value * 0.45),
                    duration: const Duration(milliseconds: 120),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Processing Payment...',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Please wait. We are confirming your digital checkout.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            PaymentStatusView(
              success: false,
              failure: false,
              title: 'Verifying payment method',
              subtitle: 'Checking transaction details and seat availability',
              detailLabel: 'Method',
              detailValue: widget.paymentMethod.title,
              transactionId: _transactionId,
            ),
            const SizedBox(height: 16),
            TransactionSummaryCard(
              data: PaymentResultData(
                transactionId: _transactionId,
                bookingReference: _bookingReference,
                paidAmount: total,
                paymentMethodTitle: widget.paymentMethod.title,
                promoCode: widget.promoCode,
                promoDiscount: widget.promoDiscount,
                fromWallet:
                    widget.paymentMethod.type ==
                    PaymentMethodType.walletBalance,
                remainingWalletBalance:
                    widget.paymentMethod.type == PaymentMethodType.walletBalance
                    ? widget.checkoutData.remainingWalletAfterPayment(total)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _successView(BuildContext context, int total) {
    return _stateShell(
      key: const ValueKey('success'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PaymentStatusView(
            success: true,
            failure: false,
            title: 'Payment Successful',
            subtitle: 'Your ride has been paid for and is ready to confirm',
            detailLabel: 'Amount paid',
            detailValue: '$total EGP',
            transactionId: _transactionId,
            secondaryDetailLabel: 'Booking reference',
            secondaryDetailValue: _bookingReference,
          ),
          const SizedBox(height: 16),
          TransactionSummaryCard(data: _result!),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Continue To Booking Confirmation',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => BookingConfirmationScreen(
                          seat: widget.checkoutData.selectedSeat,
                          vehicleId: widget.checkoutData.vehicleNumber,
                          driver: widget.checkoutData.driverName,
                          departureTime: widget.checkoutData.departureTime,
                          destination: widget.checkoutData.destination,
                          bookingReference: _bookingReference,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _failureView(BuildContext context) {
    return _stateShell(
      key: const ValueKey('failure'),
      child: AppSurface(
        radius: 28,
        padding: const EdgeInsets.all(20),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaymentStatusView(
              success: false,
              failure: true,
              title: 'Payment Failed',
              subtitle: 'A simulated issue interrupted the checkout flow',
              detailLabel: 'Reason',
              detailValue: 'Network issue / timeout',
              transactionId: _transactionId,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Retry',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Change Payment Method',
                    outline: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stateShell({required Key key, required Widget child}) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
