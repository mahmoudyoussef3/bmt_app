import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Explains a failed confirm in the rider's terms.
///
/// A booking can fail for reasons the rider can act on — the seat went to
/// someone faster, the hold ran out, they already hold a booking — so each
/// backend code is answered with the sentence that tells them what to do next.
Future<void> showWizardBookingErrorDialog(
  BuildContext context, {
  required String reason,
}) {
  final l10n = context.l10n;
  // Only one active booking is allowed at a time, so the way out is the
  // bookings list rather than another attempt.
  final isDuplicate = reason.contains('duplicate_active_booking');

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: ClientColors.surfaceFor(dialogContext),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.booking_bookingFailed,
        style: ClientTypography.headingSmall(
          dialogContext,
        ).copyWith(color: ClientColors.journeyRed),
      ),
      content: Text(
        _messageFor(dialogContext, reason),
        style: ClientTypography.bodySmall(dialogContext),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            if (isDuplicate) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          child: Text(
            isDuplicate ? l10n.booking_openMyBookings : l10n.booking_ok,
            style: const TextStyle(color: ClientColors.primary),
          ),
        ),
      ],
    ),
  );
}

String _messageFor(BuildContext context, String reason) {
  final l10n = context.l10n;

  if (reason.contains('seat_unavailable')) return l10n.booking_seatJustTaken;
  if (reason.contains('lock_expired')) return l10n.booking_seatHoldExpired;
  if (reason.contains('duplicate_active_booking')) {
    return l10n.booking_duplicateActiveBooking;
  }
  if (reason.contains('booking_reference_missing')) {
    return l10n.booking_referenceNotCreated;
  }
  if (reason.contains('card_payment_unavailable')) {
    return l10n.booking_cardPaymentUnavailable;
  }
  if (reason.contains('card_payment_declined')) {
    return l10n.booking_cardPaymentDeclined;
  }
  if (reason.contains('card_payment_not_completed')) {
    return l10n.booking_cardPaymentNotCompleted;
  }
  return reason;
}
