import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String seat;
  final String vehicleId;
  final String driver;
  final String departureTime;
  final String destination;
  final String? bookingReference;

  const BookingConfirmationScreen({
    super.key,
    required this.seat,
    required this.vehicleId,
    required this.driver,
    required this.departureTime,
    required this.destination,
    this.bookingReference,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with TickerProviderStateMixin {
  bool _processing = true;
  late final String _bookingId;
  late final AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _bookingId = _generateBookingId();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Simulate processing then show success
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _processing = false);
      _checkController.forward();
    });
  }

  String _generateBookingId() {
    final rng = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Booking',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  child: _processing
                      ? _buildProcessing(context)
                      : _buildSuccess(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Back to Home',
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      outline: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Track Vehicle',
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/tracking'),
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

  Widget _buildProcessing(BuildContext context) {
    return Column(
      key: const ValueKey('processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(strokeWidth: 6),
        ),
        const SizedBox(height: 18),
        Text(
          'Processing your booking...',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'This should only take a moment',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bookingReference = widget.bookingReference ?? _bookingId;
    return SingleChildScrollView(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _checkController,
                curve: Curves.elasticOut,
              ),
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primary.withAlpha(180)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, size: 60, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Booking Confirmed',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Your seat is reserved — confirmation below',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          AppSurface(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booking Reference',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      bookingReference,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.destination,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Seat ${widget.seat}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Departs',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          widget.departureTime,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        widget.driver
                            .split(' ')
                            .map((s) => s.isEmpty ? '' : s[0])
                            .take(2)
                            .join(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driver,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vehicle ${widget.vehicleId}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Notes', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  'Please arrive 10 minutes before departure. Cancellation allowed up to 1 hour before departure.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
