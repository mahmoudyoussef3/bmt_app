import '../../domain/entities/operation_booking.dart';

class BookingFilters {
  final String search;
  final String route;
  final String date;
  final BookingPaymentMethod? paymentMethod;

  /// Payment state is the axis the office actually works along (which receipts
  /// are rejected, which are still pending), and it is independent of the
  /// booking status the tabs filter by — so it is a filter of its own.
  final PaymentStatus? paymentStatus;

  const BookingFilters({
    this.search = '',
    this.route = '',
    this.date = '',
    this.paymentMethod,
    this.paymentStatus,
  });

  /// Whether anything is narrowing the list, so the UI can offer a single
  /// "clear" affordance instead of making the operator empty four inputs.
  bool get isActive =>
      search.trim().isNotEmpty ||
      route.trim().isNotEmpty ||
      date.trim().isNotEmpty ||
      paymentMethod != null ||
      paymentStatus != null;

  int get activeCount => [
    search.trim().isNotEmpty,
    route.trim().isNotEmpty,
    date.trim().isNotEmpty,
    paymentMethod != null,
    paymentStatus != null,
  ].where((active) => active).length;

  BookingFilters copyWith({
    String? search,
    String? route,
    String? date,
    BookingPaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
    PaymentStatus? paymentStatus,
    bool clearPaymentStatus = false,
  }) {
    return BookingFilters(
      search: search ?? this.search,
      route: route ?? this.route,
      date: date ?? this.date,
      paymentMethod: clearPaymentMethod
          ? null
          : paymentMethod ?? this.paymentMethod,
      paymentStatus: clearPaymentStatus
          ? null
          : paymentStatus ?? this.paymentStatus,
    );
  }
}
