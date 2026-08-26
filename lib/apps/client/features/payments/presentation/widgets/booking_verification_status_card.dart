import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

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
    final phase = _phaseContent(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: phase.color,
            boxShadow: [
              BoxShadow(
                color: phase.color.withAlpha(55),
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
            label: Text(context.l10n.payments_viewFullTripStatus),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _isRejected
              ? context.l10n.payments_rejectedHelpText
              : context.l10n.payments_pendingApprovalNotice,
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
          _infoRow(
            context,
            context.l10n.payments_bookingReferenceLabel,
            bookingReference,
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          const SizedBox(height: 14),
          _infoRow(
            context,
            context.l10n.payments_bookingStatusLabel,
            phase.statusLabel,
            valueColor: phase.statusColor,
          ),
          const SizedBox(height: 14),
          if (_isRejected && reason != null && reason.isNotEmpty)
            _infoRow(
              context,
              context.l10n.payments_reasonLabel,
              reason,
              valueColor: ClientColors.journeyRed,
            )
          else if (!_isApproved)
            _infoRow(
              context,
              context.l10n.payments_estimatedReviewTimeLabel,
              context.l10n.payments_estimatedReviewTimeValue,
            ),
        ],
      ),
    );
  }

  _StatusPhase _phaseContent(BuildContext context) {
    final l10n = context.l10n;
    if (_isApproved) {
      return _StatusPhase(
        color: ClientColors.journeyCyan,
        icon: Icons.check_circle_rounded,
        title: l10n.payments_paymentApprovedTitle,
        subtitle: l10n.payments_paymentApprovedSubtitle,
        statusLabel: l10n.payments_statusApproved,
        statusColor: ClientColors.journeyCyan,
      );
    }
    if (_isRejected) {
      return _StatusPhase(
        color: ClientColors.journeyRed,
        icon: Icons.cancel_rounded,
        title: l10n.payments_paymentRejectedTitle,
        subtitle: l10n.payments_paymentRejectedSubtitle,
        statusLabel: l10n.payments_statusRejected,
        statusColor: ClientColors.journeyRed,
      );
    }
    return _StatusPhase(
      color: ClientColors.journeyAmber,
      icon: Icons.hourglass_top_rounded,
      title: l10n.payments_paymentReceiptSubmittedTitle,
      subtitle: l10n.payments_paymentReceiptSubmittedSubtitle,
      statusLabel: l10n.payments_statusPendingVerification,
      statusColor: ClientColors.journeyAmber,
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
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
}
