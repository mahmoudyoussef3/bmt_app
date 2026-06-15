import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/booking_confirmation_screen.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/book_trip_seat_usecase.dart';

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
  late final AnimationController _loaderRotationController;

  bool _loading = true;
  bool _failed = false;
  int _currentStepIndex = 0;
  Timer? _stepTimer;
  Timer? _transitionTimer;

  late final String _transactionId;
  late final String _bookingReference;

  final List<String> _progressSteps = [
    'Establishing secure fintech connection...',
    'Verifying account status and limit...',
    'Reserving seat and finalising ticket metadata...',
  ];

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
      duration: const Duration(milliseconds: 1000),
    );

    _loaderRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Rotate step text during loading
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
    final shouldFail = widget.simulateFailure;
    if (shouldFail) {
      await Future.delayed(const Duration(milliseconds: 2800));
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    try {
      final bookTripSeat = clientGetIt<BookTripSeatUseCase>();

      // Get the payment amount
      final total = widget.checkoutData.totalForDiscount(widget.promoDiscount);

      final bookingId = await bookTripSeat({
        'p_trip_id': widget.checkoutData.tripId,
        'p_seat_id': widget.checkoutData.selectedSeatId,
        'p_seat': widget.checkoutData.selectedSeat,
        'p_pricing_id': null,
        'p_pickup_point_id': null,
        'p_dropoff_point_id': null,
        'p_passenger_name': 'Me', // Assuming current user
        'p_phone': '',
        'p_route': widget.checkoutData.route,
        'p_trip_time': widget.checkoutData.departureTime,
        'p_trip_date': widget.checkoutData.tripDate,
        'p_payment_method': widget.paymentMethod.title,
        'p_payment_amount': total,
        'p_pickup_point_name': widget.checkoutData.pickupPoint,
        'p_dropoff_point_name': widget.checkoutData.destination,
      });

      if (!mounted) return;
      setState(() {
        _bookingReference = bookingId.substring(0, 8).toUpperCase();
        _loading = false;
        _failed = false;
      });
      _checkController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  String _generateId({required String prefix}) {
    final rng = math.Random();
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
    _loaderRotationController.dispose();
    _stepTimer?.cancel();
    _transitionTimer?.cancel();
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
              // Screen Header
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
                    duration: const Duration(milliseconds: 350),
                    child: _loading
                        ? _buildProcessingView(context, scheme, total)
                        : _failed
                        ? _buildFailureView(context, scheme)
                        : _buildSuccessView(context, scheme, total),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SCREEN 3: PAYMENT PROCESSING VIEW ---
  Widget _buildProcessingView(
    BuildContext context,
    ColorScheme scheme,
    int total,
  ) {
    return _stateShell(
      key: const ValueKey('processing'),
      child: AppSurface(
        radius: 28,
        padding: const EdgeInsets.all(22),
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outline.withAlpha(55)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rotating Fintech Loader
            Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _loaderRotationController,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: LoaderRingPainter(
                      scheme.primary,
                      scheme.secondary,
                    ),
                  ),
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: scheme.primary,
                    size: 38,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Processing Payment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Please do not close this screen or press back button.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withAlpha(160),
              ),
            ),
            const SizedBox(height: 20),

            // Step-by-step Status Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outline.withAlpha(45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _progressSteps[_currentStepIndex],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildDetailTextRow('Method:', widget.paymentMethod.title),
                  const SizedBox(height: 6),
                  _buildDetailTextRow('Transaction ID:', _transactionId),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Booking summary summary
            AppSurface(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: scheme.surfaceContainerLow,
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bus_rounded,
                    color: scheme.secondary,
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Driver: ${widget.checkoutData.driverName} • Seat: ${widget.checkoutData.selectedSeat}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$total EGP',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: scheme.primary,
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

  // --- SCREEN 4: PAYMENT SUCCESS VIEW ---
  Widget _buildSuccessView(
    BuildContext context,
    ColorScheme scheme,
    int total,
  ) {
    return _stateShell(
      key: const ValueKey('success'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSurface(
            radius: 28,
            padding: const EdgeInsets.all(22),
            color: scheme.surfaceContainerHigh,
            border: Border.all(color: Colors.green.withAlpha(60)),
            child: Column(
              children: [
                // Custom Confetti & Expanding checkmark animation
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
                            colors: [Colors.green, Colors.teal],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withAlpha(45),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Confetti Particles
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: ConfettiPainter(progress: _checkController),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Successful',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your booking reference has been confirmed',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 20),

                // Transaction confirmation card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outline.withAlpha(45)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailTextRow(
                        'Booking Ref:',
                        _bookingReference,
                        isBoldValue: true,
                        valueColor: scheme.primary,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailTextRow('Paid Amount:', '$total EGP'),
                      const SizedBox(height: 6),
                      _buildDetailTextRow(
                        'Payment Method:',
                        widget.paymentMethod.title,
                      ),
                      const SizedBox(height: 6),
                      _buildDetailTextRow('Transaction ID:', _transactionId),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: View Ticket & Back to Home
          Row(
            children: [
              Expanded(
                child: AppButton(
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
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Back to Home',
                  outline: true,
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SCREEN 5: PAYMENT FAILURE VIEW ---
  Widget _buildFailureView(BuildContext context, ColorScheme scheme) {
    return _stateShell(
      key: const ValueKey('failure'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSurface(
            radius: 28,
            padding: const EdgeInsets.all(22),
            color: scheme.surfaceContainerHigh,
            border: Border.all(color: scheme.error.withAlpha(60)),
            child: Column(
              children: [
                // Error Illustration
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.error.withAlpha(15),
                    border: Border.all(color: scheme.error.withAlpha(45)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.gpp_bad_rounded,
                      size: 48,
                      color: scheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Payment Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your transaction could not be processed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 20),

                // Failure Reason Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outline.withAlpha(55)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason for Failure',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMockFailureReason(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildDetailTextRow('Transaction ID:', _transactionId),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: Retry & Contact Support
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Retry Payment',
                  onPressed: () {
                    // Navigate back to checkout screen to let them retry
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Contact Support',
                  outline: true,
                  onPressed: () {
                    _showSupportDialog(context, scheme);
                  },
                ),
              ),
            ],
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
    String label,
    String value, {
    bool isBoldValue = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBoldValue ? FontWeight.w900 : FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _getMockFailureReason() {
    if (widget.paymentMethod.type == PaymentMethodType.walletBalance) {
      return 'Insufficient wallet balance for this transaction.';
    }
    if (widget.paymentMethod.type == PaymentMethodType.creditCard) {
      return '3D Secure authorization failed / timeout.';
    }
    return 'Verification error. The receipt upload screenshot was rejected / invalid transaction reference.';
  }

  void _showSupportDialog(BuildContext context, ColorScheme scheme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Contact Customer Support',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Our customer support agents are ready to assist you. Reference ticket number: $_transactionId',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withAlpha(200),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: scheme.primary)),
            ),
          ],
        );
      },
    );
  }
}

// --- CUSTOM PAINTER: ROTATING LOADER ARC ---
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

    // Draw background dim track
    paint.color = primaryColor.withAlpha(30);
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);

    // Draw active gradient arc
    paint.color = primaryColor;
    canvas.drawArc(rect, 0, 1.2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- CUSTOM PAINTER: CONFETTI PARTICLES ---
class ConfettiPainter extends CustomPainter {
  final Animation<double> progress;

  ConfettiPainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress.value == 0) return;

    final random = math.Random(42);
    final center = Offset(size.width / 2, size.height / 2);
    final count = 28;
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
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.amber;
      default:
        return Colors.pink;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
