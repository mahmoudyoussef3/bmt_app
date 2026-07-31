import '../../domain/entities/operation_booking.dart';

/// One tab on the queue board.
///
/// The board used to expose exactly the six [BookingStatus] values, which left
/// the operator's most frequent question — *what is waiting for me right now?* —
/// without a tab at all: a receipt awaiting review can sit on a `draft`, a
/// `reserved` **or** a `confirmed` booking, so finding the review queue meant
/// checking three tabs by hand. [needsReview] and [all] cut across status for
/// that reason; the remaining tabs still map 1:1 to a [BookingStatus].
enum BookingQueueTab {
  needsReview(null, 'بانتظار المراجعة'),
  all(null, 'كل الطلبات'),
  draft(BookingStatus.draft, null),
  reserved(BookingStatus.reserved, null),
  confirmed(BookingStatus.confirmed, null),
  boarded(BookingStatus.boarded, null),
  completed(BookingStatus.completed, null),
  cancelled(BookingStatus.cancelled, null);

  const BookingQueueTab(this.status, this._label);

  /// The status this tab filters by, or null for the cross-status tabs.
  final BookingStatus? status;

  final String? _label;

  /// Derived from [BookingStatus.label] where possible so the tab wording can
  /// never drift from the status wording used in chips and the inspector.
  String get label => _label ?? status!.label;

  bool matches(OperationBooking booking) => switch (this) {
    BookingQueueTab.needsReview => booking.awaitingReview,
    BookingQueueTab.all => true,
    _ => booking.status == status,
  };
}
