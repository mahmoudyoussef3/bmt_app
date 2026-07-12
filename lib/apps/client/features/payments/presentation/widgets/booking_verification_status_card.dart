import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

/// The live payment/booking follow-up shown while a manual-transfer receipt
/// is under review. Reflects the real `operation_bookings` payment status
/// (polled by the parent screen) instead of a static "pending" placeholder,
/// so the client can always see what actually happened to their payment.
class BookingVerificationStatusCard extends StatelessWidget {
  const BookingVerificationStatusCard({
    super.key,
    required this.bookingReference,
    required this.paymentStatus,
    this.rejectionReason,
    this.onViewBookingStatus,
  });

  final String bookingReference;
  final PaymentStatus? paymentStatus;
  final String? rejectionReason;
  final VoidCallback? onViewBookingStatus;

  bool get _isApproved => paymentStatus == PaymentStatus.paid;
  bool get _isRejected => paymentStatus == PaymentStatus.failed;

  @override
  Widget build(BuildContext context) {
    final phase = _phaseContent();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: phase.gradient),
            boxShadow: [
              BoxShadow(
                color: phase.gradient.first.withAlpha(55),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(child: Icon(phase.icon, size: 60, color: Colors.white)),
        ),
        const SizedBox(height: 24),
        Text(
          phase.title,
          textAlign: TextAlign.center,
          style: ClientTypography.headingLarge(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
        const SizedBox(height: 12),
        Text(
          phase.subtitle,
          textAlign: TextAlign.center,
          style: ClientTypography.bodyMedium(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildStatusCard(context, phase),
        if (onViewBookingStatus != null) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onViewBookingStatus,
            icon: const Icon(Icons.timeline_rounded, size: 18),
            label: const Text('View Full Trip & Payment Status'),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _isRejected
              ? 'You can contact support for help or try booking another trip.'
              : 'You will receive a notification once your payment has been approved.',
          textAlign: TextAlign.center,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, _StatusPhase phase) {
    final reason = rejectionReason?.trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(context, 'Booking Reference', bookingReference),
          const SizedBox(height: 14),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          const SizedBox(height: 14),
          _infoRow(
            context,
            'Booking Status',
            phase.statusLabel,
            valueColor: phase.statusColor,
          ),
          const SizedBox(height: 14),
          if (_isRejected && reason != null && reason.isNotEmpty)
            _infoRow(context, 'Reason', reason, valueColor: ClientColors.journeyRed)
          else if (!_isApproved)
            _infoRow(context, 'Estimated Review Time', '5–15 Minutes'),
        ],
      ),
    );
  }

  _StatusPhase _phaseContent() {
    if (_isApproved) {
      return _StatusPhase(
        gradient: const [ClientColors.journeyGreen, Color(0xFF14B8A6)],
        icon: Icons.check_circle_rounded,
        title: 'Payment Approved',
        subtitle:
            'Your payment was verified. Your seat is confirmed and ready to track.',
        statusLabel: 'Approved',
        statusColor: ClientColors.journeyGreen,
      );
    }
    if (_isRejected) {
      return _StatusPhase(
        gradient: const [ClientColors.journeyRed, Color(0xFFB91C1C)],
        icon: Icons.cancel_rounded,
        title: 'Payment Rejected',
        subtitle:
            "We couldn't verify this payment. Contact support or try booking again.",
        statusLabel: 'Rejected',
        statusColor: ClientColors.journeyRed,
      );
    }
    return const _StatusPhase(
      gradient: [Colors.orangeAccent, Colors.deepOrange],
      icon: Icons.hourglass_top_rounded,
      title: 'Payment Receipt Submitted',
      subtitle:
          'Your booking request has been received. Our finance team is reviewing your payment.',
      statusLabel: 'Pending Verification',
      statusColor: Colors.orange,
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: ClientTypography.labelMedium(context).copyWith(
              color: valueColor ?? ClientColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPhase {
  const _StatusPhase({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
  });

  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
}
