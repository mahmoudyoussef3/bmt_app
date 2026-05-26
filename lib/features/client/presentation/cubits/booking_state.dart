part of 'booking_cubit.dart';

enum BookingStep {
  location,
  destination,
  arrival,
  vehicles,
  seats,
  confirmation,
}

class BookingState {
  final BookingStep step;
  final Location? pickupLocation;
  final Location? destination;
  final DateTime? arrivalTime;
  final List<Trip> availableTrips;
  final Trip? selectedTrip;
  final Seat? selectedSeat;
  final Booking? confirmedBooking;

  const BookingState({
    this.step = BookingStep.location,
    this.pickupLocation,
    this.destination,
    this.arrivalTime,
    this.availableTrips = const [],
    this.selectedTrip,
    this.selectedSeat,
    this.confirmedBooking,
  });

  BookingState copyWith({
    BookingStep? step,
    Location? pickupLocation,
    Location? destination,
    DateTime? arrivalTime,
    List<Trip>? availableTrips,
    Trip? selectedTrip,
    Seat? selectedSeat,
    Booking? confirmedBooking,
  }) {
    return BookingState(
      step: step ?? this.step,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destination: destination ?? this.destination,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      availableTrips: availableTrips ?? this.availableTrips,
      selectedTrip: selectedTrip ?? this.selectedTrip,
      selectedSeat: selectedSeat ?? this.selectedSeat,
      confirmedBooking: confirmedBooking ?? this.confirmedBooking,
    );
  }
}
