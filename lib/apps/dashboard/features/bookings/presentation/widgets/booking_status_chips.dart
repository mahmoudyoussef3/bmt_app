import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/operation_booking.dart';

/// The colour + icon a booking or payment state is drawn with, everywhere.
///
/// The board, the cards, the KPI strip and the charts each used to pick their
/// own colour for the same state, so "مؤكد" was green in one place and blue two
/// rows down. One table fixes that.
///
/// A style names a **semantic tone**, not a pair of colours. It used to hold
/// two `Color`s read straight off [AppStatusColors], which are light-mode
/// constants — so every chip on this screen kept its pale `#CFFAFE` fill after
/// a switch to dark mode and lit up the page. [resolve] hands back the pair for
/// the theme actually in effect.
class BookingStatusStyle {
  const BookingStatusStyle(this.tone, this.icon);

  final AppStatusTone tone;
  final IconData icon;

  /// The `tint` / `ink` / `accent` triple for the current brightness.
  AppStatusStyle resolve(BuildContext context) =>
      AppStatusStyle.of(context, tone);
}

BookingStatusStyle bookingStatusStyle(BookingStatus status) => switch (status) {
  BookingStatus.draft => const BookingStatusStyle(
    AppStatusTone.neutral,
    Icons.edit_note_rounded,
  ),
  BookingStatus.reserved => const BookingStatusStyle(
    AppStatusTone.info,
    Icons.event_seat_rounded,
  ),
  BookingStatus.confirmed => const BookingStatusStyle(
    AppStatusTone.success,
    Icons.verified_rounded,
  ),
  BookingStatus.boarded => const BookingStatusStyle(
    AppStatusTone.special,
    Icons.directions_bus_filled_rounded,
  ),
  BookingStatus.completed => const BookingStatusStyle(
    AppStatusTone.success,
    Icons.task_alt_rounded,
  ),
  BookingStatus.cancelled => const BookingStatusStyle(
    AppStatusTone.neutral,
    Icons.block_rounded,
  ),
};

BookingStatusStyle paymentStatusStyle(PaymentStatus status) => switch (status) {
  PaymentStatus.pending => const BookingStatusStyle(
    AppStatusTone.neutral,
    Icons.schedule_rounded,
  ),
  PaymentStatus.submitted => const BookingStatusStyle(
    AppStatusTone.warning,
    Icons.upload_file_rounded,
  ),
  PaymentStatus.underReview => const BookingStatusStyle(
    AppStatusTone.warning,
    Icons.hourglass_top_rounded,
  ),
  PaymentStatus.approved => const BookingStatusStyle(
    AppStatusTone.success,
    Icons.paid_rounded,
  ),
  PaymentStatus.rejected => const BookingStatusStyle(
    AppStatusTone.error,
    Icons.cancel_rounded,
  ),
  PaymentStatus.refunded => const BookingStatusStyle(
    AppStatusTone.special,
    Icons.undo_rounded,
  ),
  PaymentStatus.failed => const BookingStatusStyle(
    AppStatusTone.error,
    Icons.error_rounded,
  ),
  PaymentStatus.cancelled => const BookingStatusStyle(
    AppStatusTone.neutral,
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

  BookingStateChip.booking(
    BookingStatus status, {
    super.key,
    this.dense = false,
  }) : label = status.label,
       style = bookingStatusStyle(status);

  BookingStateChip.payment(
    PaymentStatus status, {
    super.key,
    this.dense = false,
  }) : label = status.label,
       style = paymentStatusStyle(status);

  final String label;
  final BookingStatusStyle style;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = style.resolve(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.small : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.ink.withAlpha(45)),
      ),
      // Intrinsic width so a long Arabic label is never clipped inside a table
      // cell, and shrinks with the row instead of forcing it wider.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: dense ? 12 : 14, color: tone.ink),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (dense ? text.labelSmall : text.labelMedium)?.copyWith(
                color: tone.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
