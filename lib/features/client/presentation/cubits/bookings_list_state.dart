part of 'bookings_list_cubit.dart';

class BookingsListState {
  final List<Booking> bookings;
  final bool isLoading;

  const BookingsListState({this.bookings = const [], this.isLoading = false});

  BookingsListState copyWith({List<Booking>? bookings, bool? isLoading}) {
    return BookingsListState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
