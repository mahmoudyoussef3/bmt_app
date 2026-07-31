import '../../domain/entities/operation_booking.dart';

/// Sortable columns on the queue board.
///
/// The board is the operator's working list, so it has to answer more than one
/// ordering question: *what came in last* (triage), *how much money is on this
/// row* (finance), *which trip is this for* (dispatch). One fixed newest-first
/// order forced the operator to scan instead of sort.
enum BookingSortField {
  createdAt('الأحدث'),
  passenger('العميل'),
  route('المسار'),
  amount('المبلغ'),
  tripDate('تاريخ الرحلة');

  const BookingSortField(this.label);

  final String label;

  int compare(OperationBooking a, OperationBooking b) => switch (this) {
    BookingSortField.createdAt => a.createdAt.compareTo(b.createdAt),
    BookingSortField.passenger => a.passengerName.compareTo(b.passengerName),
    BookingSortField.route => a.route.compareTo(b.route),
    BookingSortField.amount => a.paymentAmount.compareTo(b.paymentAmount),
    // Trip dates are ISO `yyyy-MM-dd` strings, so lexical order is chronological
    // order; the departure time breaks ties within the same day.
    BookingSortField.tripDate =>
      '${a.date} ${a.tripTime}'.compareTo('${b.date} ${b.tripTime}'),
  };
}
