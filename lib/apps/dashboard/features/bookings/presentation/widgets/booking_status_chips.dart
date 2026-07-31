import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/operation_booking.dart';

/// The colour + icon a booking or payment state is drawn with, everywhere.
///
/// The board, the cards, the KPI strip and the charts each used to pick their
/// own colour for the same state, so "مؤكد" was green in one place and blue two
/// rows down. One table fixes that, and keeps every pairing on the WCAG-AA
/// container/on-container pairs from [AppStatusColors].
class BookingStatusStyle {
  const BookingStatusStyle(this.container, this.onContainer, this.icon);

  final Color container;
  final Color onContainer;
  final IconData icon;
}

BookingStatusStyle bookingStatusStyle(BookingStatus status) => switch (status) {
  BookingStatus.draft => const BookingStatusStyle(
    AppStatusColors.neutralContainer,
    AppStatusColors.onNeutralContainer,
    Icons.edit_note_rounded,
  ),
  BookingStatus.reserved => const BookingStatusStyle(
    AppStatusColors.infoContainer,
    AppStatusColors.onInfoContainer,
    Icons.event_seat_rounded,
  ),
  BookingStatus.confirmed => const BookingStatusStyle(
    AppStatusColors.successContainer,
    AppStatusColors.onSuccessContainer,
    Icons.verified_rounded,
  ),
  BookingStatus.boarded => const BookingStatusStyle(
    AppStatusColors.specialContainer,
    AppStatusColors.onSpecialContainer,
    Icons.directions_bus_filled_rounded,
  ),
  BookingStatus.completed => const BookingStatusStyle(
    AppStatusColors.successContainer,
    AppStatusColors.onSuccessContainer,
    Icons.task_alt_rounded,
  ),
  BookingStatus.cancelled => const BookingStatusStyle(
    AppStatusColors.neutralContainer,
    AppStatusColors.onNeutralContainer,
    Icons.block_rounded,
  ),
};

BookingStatusStyle paymentStatusStyle(PaymentStatus status) =>
    switch (status) {
      PaymentStatus.pending => const BookingStatusStyle(
        AppStatusColors.neutralContainer,
        AppStatusColors.onNeutralContainer,
        Icons.schedule_rounded,
      ),
      PaymentStatus.submitted => const BookingStatusStyle(
        AppStatusColors.warningContainer,
        AppStatusColors.onWarningContainer,
        Icons.upload_file_rounded,
      ),
      PaymentStatus.underReview => const BookingStatusStyle(
        AppStatusColors.warningContainer,
        AppStatusColors.onWarningContainer,
        Icons.hourglass_top_rounded,
      ),
      PaymentStatus.approved => const BookingStatusStyle(
        AppStatusColors.successContainer,
        AppStatusColors.onSuccessContainer,
        Icons.paid_rounded,
      ),
      PaymentStatus.rejected => const BookingStatusStyle(
        AppStatusColors.errorContainer,
        AppStatusColors.onErrorContainer,
        Icons.cancel_rounded,
      ),
      PaymentStatus.refunded => const BookingStatusStyle(
        AppStatusColors.specialContainer,
        AppStatusColors.onSpecialContainer,
        Icons.undo_rounded,
      ),
      PaymentStatus.failed => const BookingStatusStyle(
        AppStatusColors.errorContainer,
        AppStatusColors.onErrorContainer,
        Icons.error_rounded,
      ),
      PaymentStatus.cancelled => const BookingStatusStyle(
        AppStatusColors.neutralContainer,
        AppStatusColors.onNeutralContainer,
        Icons.block_rounded,
      ),
    };

/// A state pill: tinted background, matching icon, matching label.
///
/// The board previously merged both states into one neutral grey chip reading
/// `محجوز / تم الرفع`, which carried no urgency and no colour — the operator had
/// to read every row to find the ones needing a decision.
class BookingStateChip extends StatelessWidget {
  const BookingStateChip({
    super.key,
    required this.label,
    required this.style,
    this.dense = false,
  });

  BookingStateChip.booking(BookingStatus status, {super.key, this.dense = false})
    : label = status.label,
      style = bookingStatusStyle(status);

  BookingStateChip.payment(PaymentStatus status, {super.key, this.dense = false})
    : label = status.label,
      style = paymentStatusStyle(status);

  final String label;
  final BookingStatusStyle style;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.small : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: style.container,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.onContainer.withAlpha(45)),
      ),
      // Intrinsic width so a long Arabic label is never clipped inside a table
      // cell, and shrinks with the row instead of forcing it wider.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: dense ? 12 : 14, color: style.onContainer),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (dense ? text.labelSmall : text.labelMedium)?.copyWith(
                color: style.onContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
