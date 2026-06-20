import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String seat;
  final String vehicleId;
  final String driver;
  final String departureTime;
  final String destination;
  final String? bookingReference;
  final String? bookingId;

  const BookingConfirmationScreen({
    super.key,
    required this.seat,
    required this.vehicleId,
    required this.driver,
    required this.departureTime,
    required this.destination,
    this.bookingReference,
    this.bookingId,
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
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Booking',
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
                    child: ClientButton.secondary(
                      label: 'Back to Home',
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClientButton(
                      label: 'Track Vehicle',
                      onPressed: () => Navigator.of(context).pushNamed(
                        '/tracking',
                        arguments: {
                          if (widget.bookingId != null)
                            'bookingId': widget.bookingId,
                        },
                      ),
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
        const SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            color: ClientColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Processing your booking...',
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
        const SizedBox(height: 6),
        Text(
          'This should only take a moment',
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final bookingReference = widget.bookingReference ?? _bookingId;
    final driverInitials = widget.driver
        .split(' ')
        .map((s) => s.isEmpty ? '' : s[0])
        .take(2)
        .join();

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
                gradient: const LinearGradient(
                  colors: [ClientColors.primary, Color(0xFF1554C8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ClientColors.primary.withAlpha(55),
                    blurRadius: 24,
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
            style: ClientTypography.headingLarge(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
          const SizedBox(height: 6),
          Text(
            'Your seat is reserved — confirmation below',
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: 18),
          Container(
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
                    Expanded(
                      child: Text(
                        'Booking Reference',
                        style: ClientTypography.bodySmall(context).copyWith(
                          color: ClientColors.textSecondaryFor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        bookingReference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: ClientTypography.labelMedium(context).copyWith(
                          color: ClientColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.destination,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.headingSmall(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Seat ${widget.seat}',
                            style: ClientTypography.bodySmall(context).copyWith(
                              color: ClientColors.textSecondaryFor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Departs',
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                        Text(
                          widget.departureTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.bodyMedium(
                            context,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: ClientColors.borderFor(context)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: ClientColors.primaryLight,
                      child: Text(
                        driverInitials,
                        style: ClientTypography.labelMedium(
                          context,
                        ).copyWith(color: ClientColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driver,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.bodyMedium(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vehicle ${widget.vehicleId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.bodySmall(context).copyWith(
                              color: ClientColors.textSecondaryFor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: ClientColors.borderFor(context)),
                const SizedBox(height: 10),
                Text(
                  'Notes',
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please arrive 10 minutes before departure. Cancellation allowed up to 1 hour before departure.',
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    height: 1.4,
                  ),
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
