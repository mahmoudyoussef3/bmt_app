import 'package:flutter/material.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import 'booking_action_dialogs.dart';

/// Wires a single booking's review action to the matching dialog + cubit call.
/// Shared by the card, the table row and the details panel so the wording and
/// behaviour stay identical everywhere.
void approveBooking(
  BuildContext context,
  BookingsCubit cubit,
  OperationBooking booking,
) {
  openApprovalDialog(
    context,
    message:
        'سيتم قبول دفع ${booking.passengerName} وتأكيد الحجز ${booking.bookingNumber}.',
    onConfirm: (note) => cubit.approveBooking(booking.id, note),
  );
}

void rejectBooking(
  BuildContext context,
  BookingsCubit cubit,
  OperationBooking booking,
) {
  openRejectionDialog(
    context,
    message:
        'سيتم رفض دفع ${booking.passengerName} للحجز ${booking.bookingNumber} وتحرير المقعد.',
    onConfirm: (reason) => cubit.rejectBooking(booking.id, reason),
  );
}

void requestReupload(
  BuildContext context,
  BookingsCubit cubit,
  OperationBooking booking,
) {
  openReuploadDialog(
    context,
    message: 'سيُطلب من ${booking.passengerName} إعادة رفع إيصال الدفع.',
    onConfirm: (reason) => cubit.requestReupload(booking.id, reason),
  );
}
