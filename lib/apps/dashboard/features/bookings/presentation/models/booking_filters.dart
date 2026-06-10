import '../../domain/entities/operation_booking.dart';

class BookingFilters {
  final String search;
  final String route;
  final String date;
  final BookingPaymentMethod? paymentMethod;
  final BookingPriority? priority;

  const BookingFilters({
    this.search = '',
    this.route = '',
    this.date = '',
    this.paymentMethod,
    this.priority,
  });

  BookingFilters copyWith({
    String? search,
    String? route,
    String? date,
    BookingPaymentMethod? paymentMethod,
    BookingPriority? priority,
    bool clearPaymentMethod = false,
    bool clearPriority = false,
  }) {
    return BookingFilters(
      search: search ?? this.search,
      route: route ?? this.route,
      date: date ?? this.date,
      paymentMethod: clearPaymentMethod
          ? null
          : paymentMethod ?? this.paymentMethod,
      priority: clearPriority ? null : priority ?? this.priority,
    );
  }
}
