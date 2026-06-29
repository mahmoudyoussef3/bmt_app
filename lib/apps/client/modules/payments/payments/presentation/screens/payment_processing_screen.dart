import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/modules/payments/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/modules/payments/payments/domain/usecases/create_card_payment_session_usecase.dart';
import 'package:bmt_app/apps/client/modules/payments/payments/presentation/screens/booking_confirmation_screen.dart';
import 'package:bmt_app/apps/client/modules/payments/payments/presentation/screens/paymob_checkout_webview_screen.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/modules/booking/seat_selection/domain/usecases/confirm_seat_booking_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final PaymentCheckoutData checkoutData;
  final PaymentMethodData paymentMethod;
  final String? promoCode;
  final int promoDiscount;
  final String? receiptUrl;

  const PaymentProcessingScreen({
    super.key,
    required this.checkoutData,
    required this.paymentMethod,
    required this.promoCode,
    required this.promoDiscount,
    this.receiptUrl,
  });

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _checkController;
  late final AnimationController _loaderRotationController;

  bool _loading = true;
  bool _failed = false;
  bool _externalCardCheckout = false;
  String? _failureReason;
  int _currentStepIndex = 0;
  Timer? _stepTimer;
  Timer? _transitionTimer;

  late String _transactionId;
  late String _bookingReference;
  String? _bookingId;

  final List<String> _progressSteps = [
    'Establishing secure fintech connection...',
    'Verifying account status and limit...',
    'Reserving seat and finalising ticket metadata...',
  ];

  @override
  void initState() {
    super.initState();
    _transactionId = 'Pending';
    _bookingReference = 'Pending';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _loaderRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _progressSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
      } else {
        timer.cancel();
      }
    });

    _processBooking();
  }

  Future<void> _processBooking() async {
    try {
      final confirmSeatBooking = clientGetIt<ConfirmSeatBookingUseCase>();
      final total = widget.checkoutData.totalForDiscount(widget.promoDiscount);

      final booking = await confirmSeatBooking({
        'p_trip_id': widget.checkoutData.tripId,
        'p_seat_id': widget.checkoutData.selectedSeatId,
        'p_seat_label': widget.checkoutData.selectedSeat,
        'p_pricing_id': null,
        'p_pickup_point_id': null,
        'p_dropoff_point_id': null,
        'p_passenger_name': Supabase.instance.client.auth.currentUser
                ?.userMetadata?['full_name']
                ?.toString() ??
            '',
        'p_phone': Supabase.instance.client.auth.currentUser
                ?.userMetadata?['phone']
                ?.toString() ??
            '',
        'p_route': widget.checkoutData.route,
        'p_trip_time': widget.checkoutData.departureTime,
        'p_trip_date': widget.checkoutData.tripDate,
        'p_payment_method': _paymentMethodCode(widget.paymentMethod.type),
        'p_payment_amount': total,
        'p_pickup_point_name': widget.checkoutData.pickupPoint,
        'p_dropoff_point_name': widget.checkoutData.destination,
        'p_receipt_url': widget.receiptUrl,
      });

      if (!mounted) return;
      final bookingId = booking['booking_id']?.toString() ?? '';
      _bookingId = bookingId.isEmpty ? null : bookingId;
      _bookingReference =
          booking['booking_number']?.toString() ??
          (bookingId.isEmpty
              ? null
              : bookingId.substring(0, 8).toUpperCase()) ??
          _bookingReference;
      _transactionId = _bookingReference;

      if (widget.paymentMethod.type == PaymentMethodType.creditCard) {
        final createCardSession =
            clientGetIt<CreateCardPaymentSessionUseCase>();
        final session = await createCardSession(
          checkoutData: widget.checkoutData,
          paymentMethod: widget.paymentMethod,
          bookingId: bookingId,
          amount: total,
        );
        _transactionId = session.gatewayReference;
        if (!mounted) return;
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymobCheckoutWebViewScreen(
              checkoutUrl: session.checkoutUrl,
              bookingReference: _bookingReference,
            ),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = false;
        _failureReason = null;
        _externalCardCheckout =
            widget.paymentMethod.type == PaymentMethodType.creditCard;
      });
      _checkController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _failureReason = _cleanFailureReason(e);
      });
    }
  }

  String _paymentMethodCode(PaymentMethodType type) {
    return switch (type) {
      PaymentMethodType.creditCard => 'credit_card',
      PaymentMethodType.vodafoneCash => 'mobile_wallet',
      PaymentMethodType.instapay => 'instapay',
      PaymentMethodType.walletBalance => 'wallet_balance',
      PaymentMethodType.cashOnBoarding => 'cash_on_boarding',
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    _loaderRotationController.dispose();
    _stepTimer?.cancel();
    _transitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.checkoutData.totalForDiscount(widget.promoDiscount);

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
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Secure Checkout',
                      style: ClientTypography.headingSmall(
                        context,
                      ).copyWith(color: ClientColors.textPrimaryFor(context)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _loading
                        ? _buildProcessingView(context, total)
                        : _failed
                        ? _buildFailureView(context)
                        : _buildSuccessView(context, total),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingView(BuildContext context, int total) {
    return _stateShell(
      key: const ValueKey('processing'),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _loaderRotationController,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: LoaderRingPainter(
                      ClientColors.primary,
                      ClientColors.primaryMuted,
                    ),
                  ),
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: ClientColors.surfaceFor(context),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: ClientColors.primary,
                    size: 38,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Processing Payment',
              style: ClientTypography.headingMedium(
                context,
              ).copyWith(color: ClientColors.textPrimaryFor(context)),
            ),
            const SizedBox(height: 6),
            Text(
              'Please do not close this screen or press back button.',
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ClientColors.surfaceSubtleFor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ClientColors.borderFor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ClientColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _progressSteps[_currentStepIndex],
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textPrimaryFor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: ClientColors.borderFor(context), height: 1),
                  const SizedBox(height: 12),
                  _buildDetailTextRow(
                    context,
                    'Method:',
                    widget.paymentMethod.title,
                  ),
                  const SizedBox(height: 6),
                  _buildDetailTextRow(
                    context,
                    'Transaction ID:',
                    _transactionId,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ClientColors.surfaceSubtleFor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ClientColors.borderFor(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bus_rounded,
                    color: ClientColors.textSecondaryFor(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.checkoutData.pickupPoint} → ${widget.checkoutData.destination}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textPrimaryFor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Driver: ${widget.checkoutData.driverName} • Seat: ${widget.checkoutData.selectedSeat}',
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textTertiaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$total EGP',
                    style: ClientTypography.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: ClientColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, int total) {
    return _stateShell(
      key: const ValueKey('success'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: ClientColors.journeyGreen.withAlpha(60),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _checkController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              ClientColors.journeyGreen,
                              Color(0xFF14B8A6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ClientColors.journeyGreen.withAlpha(45),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 50,
                            color: ClientColors.textInverse,
                          ),
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: ConfettiPainter(progress: _checkController),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _externalCardCheckout
                      ? 'Paymob Checkout Opened'
                      : 'Payment Submitted',
                  style: ClientTypography.headingMedium(
                    context,
                  ).copyWith(color: ClientColors.journeyGreen),
                ),
                const SizedBox(height: 4),
                Text(
                  _externalCardCheckout
                      ? 'Complete card payment in the secure Paymob page.'
                      : 'Your receipt was sent for operations review.',
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ClientColors.surfaceSubtleFor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ClientColors.borderFor(context)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailTextRow(
                        context,
                        'Booking Ref:',
                        _bookingReference,
                        isBoldValue: true,
                        valueColor: ClientColors.primary,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailTextRow(
                        context,
                        'Paid Amount:',
                        '$total EGP',
                      ),
                      const SizedBox(height: 6),
                      _buildDetailTextRow(
                        context,
                        'Payment Method:',
                        widget.paymentMethod.title,
                      ),
                      const SizedBox(height: 6),
                      _buildDetailTextRow(
                        context,
                        'Transaction ID:',
                        _transactionId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ClientButton(
            label: 'View Ticket',
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
                    bookingId: _bookingId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          ClientButton.secondary(
            label: 'Back to Home',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFailureView(BuildContext context) {
    return _stateShell(
      key: const ValueKey('failure'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: ClientColors.journeyRed.withAlpha(60)),
            ),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ClientColors.journeyRed.withAlpha(15),
                    border: Border.all(
                      color: ClientColors.journeyRed.withAlpha(45),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.gpp_bad_rounded,
                      size: 48,
                      color: ClientColors.journeyRed,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Payment Failed',
                  style: ClientTypography.headingMedium(
                    context,
                  ).copyWith(color: ClientColors.journeyRed),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your transaction could not be processed.',
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ClientColors.surfaceSubtleFor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ClientColors.borderFor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason for Failure',
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: ClientColors.textTertiaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _failureReason ?? 'Payment could not be completed.',
                        style: ClientTypography.bodyMedium(context).copyWith(
                          color: ClientColors.textPrimaryFor(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: ClientColors.borderFor(context),
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailTextRow(
                        context,
                        'Transaction ID:',
                        _transactionId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ClientButton(
            label: 'Retry Payment',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 10),
          ClientButton.secondary(
            label: 'Contact Support',
            onPressed: () => _showSupportDialog(context),
          ),
        ],
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

  Widget _buildDetailTextRow(
    BuildContext context,
    String label,
    String value, {
    bool isBoldValue = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
        Text(
          value,
          style: ClientTypography.bodySmall(context).copyWith(
            fontWeight: isBoldValue ? FontWeight.w900 : FontWeight.bold,
            color: valueColor ?? ClientColors.textPrimaryFor(context),
          ),
        ),
      ],
    );
  }

  String _cleanFailureReason(Object error) {
    final raw = error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
    if (raw.trim().isEmpty) return 'Payment could not be completed.';
    return raw;
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ClientColors.surfaceFor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Contact Customer Support',
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Our customer support agents are ready to assist you. Reference ticket number: $_transactionId',
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: ClientColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LoaderRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  LoaderRingPainter(this.primaryColor, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);

    paint.color = primaryColor.withAlpha(30);
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);

    paint.color = primaryColor;
    canvas.drawArc(rect, 0, 1.2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConfettiPainter extends CustomPainter {
  final Animation<double> progress;

  ConfettiPainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress.value == 0) return;

    final random = math.Random(42);
    final center = Offset(size.width / 2, size.height / 2);
    const count = 28;
    final maxRadius = size.width * 0.7;

    for (var i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance =
          progress.value * maxRadius * (0.4 + random.nextDouble() * 0.6);

      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      final sizeFactor = (1.0 - progress.value) * (4 + random.nextDouble() * 6);
      final color = _getConfettiColor(random.nextInt(4));

      final paint = Paint()
        ..color = color.withAlpha(
          ((1.0 - progress.value).clamp(0.0, 1.0) * 255).toInt(),
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, sizeFactor, paint);
    }
  }

  Color _getConfettiColor(int index) {
    switch (index) {
      case 0:
        return ClientColors.primary;
      case 1:
        return ClientColors.journeyGreen;
      case 2:
        return ClientColors.journeyAmber;
      default:
        return ClientColors.journeyRed;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
