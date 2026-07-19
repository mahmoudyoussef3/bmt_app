import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_confirm_dialog.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_reason_sheet.dart';

/// Cancellation reason picker followed by a confirmation dialog. Returns the
/// chosen reason once the client confirms, or null if they backed out — the
/// caller is what actually cancels the booking.
Future<String?> showTripCancellationFlow(
  BuildContext context, {
  required String tripReference,
}) async {
  final reason = await showTripCancellationReasonSheet(
    context,
    tripReference: tripReference,
  );
  if (reason == null || !context.mounted) return null;

  final confirmed = await showTripCancellationConfirmDialog(
    context,
    reason: reason,
  );
  return confirmed ? reason : null;
}
