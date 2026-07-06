import '../../domain/entities/operation_booking.dart';

class BookingFilters {
  final String search;
  final String route;
  final String date;
  final BookingPaymentMethod? paymentMethod;

  const BookingFilters({
    this.search = '',
    this.route = '',
    this.date = '',
    this.paymentMethod,
  });

  BookingFilters copyWith({
    String? search,
    String? route,
    String? date,
    BookingPaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
  }) {
    return BookingFilters(
      search: search ?? this.search,
      route: route ?? this.route,
      date: date ?? this.date,
      paymentMethod: clearPaymentMethod
          ? null
          : paymentMethod ?? this.paymentMethod,
    );
  }
}
