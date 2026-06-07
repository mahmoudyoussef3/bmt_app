import '../../domain/entities/operation_booking.dart';

class BookingFilters {
  final String search;
  final String route;
  final String date;
  final BookingStatus? status;
  final BookingPaymentMethod? paymentMethod;

  const BookingFilters({
    this.search = '',
    this.route = '',
    this.date = '',
    this.status,
    this.paymentMethod,
  });

  BookingFilters copyWith({
    String? search,
    String? route,
    String? date,
    BookingStatus? status,
    BookingPaymentMethod? paymentMethod,
    bool clearStatus = false,
    bool clearPaymentMethod = false,
  }) {
    return BookingFilters(
      search: search ?? this.search,
      route: route ?? this.route,
      date: date ?? this.date,
      status: clearStatus ? null : status ?? this.status,
      paymentMethod: clearPaymentMethod
          ? null
          : paymentMethod ?? this.paymentMethod,
    );
  }
}
