import 'dart:async';
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';

enum _ApprovalStatus { pending, approved, rejected }

class BookingApprovalScreen extends StatefulWidget {
  final String routeName;
  final String pickup;
  final String dropoff;
  final String departure;
  final String seat;
  final String package;
  final String total;

  const BookingApprovalScreen({
    super.key,
    required this.routeName,
    required this.pickup,
    required this.dropoff,
    required this.departure,
    required this.seat,
    required this.package,
    required this.total,
  });

  @override
  State<BookingApprovalScreen> createState() => _BookingApprovalScreenState();
}

class _BookingApprovalScreenState extends State<BookingApprovalScreen>
    with TickerProviderStateMixin {
  final _ApprovalStatus _status = _ApprovalStatus.pending;
  Timer? _pollTimer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    // Poll every 30 seconds for approval status from Supabase
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    // Fetch booking status from Supabase and update _status.
    // Example when wired to real repo:
    //   final s = await _repo.getBookingStatus(bookingId);
    //   if (mounted) setState(() => _status = s);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      appBar: AppBar(
        backgroundColor: ClientColors.surfaceFor(context),
        elevation: 0,
        title: Text('Booking Status', style: ClientTypography.bodyMedium(context)
            .copyWith(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(context)),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _StatusIndicator(status: _status, pulse: _pulseController),
          const SizedBox(height: 20),
          Text(_statusTitle, style: ClientTypography.headingLarge(context)),
          const SizedBox(height: 8),
          Text(_statusSubtitle,
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(context)
                  .copyWith(color: ClientColors.textSecondaryFor(context))),
          const SizedBox(height: 28),
          _BookingSummaryCard(
            routeName: widget.routeName,
            pickup: widget.pickup,
            dropoff: widget.dropoff,
            departure: widget.departure,
            seat: widget.seat,
            package: widget.package,
            total: widget.total,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: switch (_status) {
        _ApprovalStatus.pending => ClientButton.secondary(
            label: 'Back to Home',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        _ApprovalStatus.approved => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClientButton(
                label: 'Track Vehicle',
                onPressed: () => Navigator.of(context).pushReplacementNamed('/tracking'),
              ),
              const SizedBox(height: 10),
              ClientButton.secondary(
                label: 'Back to Home',
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ],
          ),
        _ApprovalStatus.rejected => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClientButton(
                label: 'Try Another Route',
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              const SizedBox(height: 10),
              ClientButton.secondary(
                label: 'Contact Support',
                onPressed: () => Navigator.of(context).pushNamed('/support'),
              ),
            ],
          ),
      },
    );
  }

  String get _statusTitle => switch (_status) {
    _ApprovalStatus.pending => 'Awaiting Approval',
    _ApprovalStatus.approved => 'Booking Approved!',
    _ApprovalStatus.rejected => 'Booking Rejected',
  };

  String get _statusSubtitle => switch (_status) {
    _ApprovalStatus.pending =>
      'Our team is reviewing your booking.\nYou\'ll be notified once approved.',
    _ApprovalStatus.approved =>
      'Your seat is confirmed. The vehicle will depart on schedule.',
    _ApprovalStatus.rejected =>
      'We couldn\'t approve this booking.\nPlease try a different route or contact support.',
  };
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status, required this.pulse});
  final _ApprovalStatus status;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      _ApprovalStatus.pending => (ClientColors.accent, Icons.hourglass_top_rounded),
      _ApprovalStatus.approved => (ClientColors.journeyGreen, Icons.check_circle_rounded),
      _ApprovalStatus.rejected => (ClientColors.journeyRed, Icons.cancel_rounded),
    };
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, child) => Transform.scale(
        scale: status == _ApprovalStatus.pending ? 0.92 + pulse.value * 0.08 : 1.0,
        child: child,
      ),
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha(20),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, size: 52, color: color),
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.routeName, required this.pickup, required this.dropoff,
    required this.departure, required this.seat, required this.package, required this.total,
  });
  final String routeName, pickup, dropoff, departure, seat, package, total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          _row(context, 'Route', routeName),
          _row(context, 'From', pickup),
          _row(context, 'To', dropoff),
          _row(context, 'Departure', departure),
          _row(context, 'Seat', seat),
          _row(context, 'Package', package),
          const Divider(height: 20),
          _row(context, 'Total', 'EGP $total', highlight: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext ctx, String label, String value, {bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: ClientTypography.bodySmall(ctx)
              .copyWith(color: ClientColors.textSecondaryFor(ctx)))),
          Text(value, style: ClientTypography.bodySmall(ctx).copyWith(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? ClientColors.primary : ClientColors.textPrimaryFor(ctx),
            fontSize: highlight ? 15 : null,
          )),
        ]),
      );
}
