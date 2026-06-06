enum SeatAvailability { available, reserved }

class SeatOption {
  const SeatOption({required this.id, required this.availability});

  final String id;
  final SeatAvailability availability;

  bool get isAvailable => availability == SeatAvailability.available;
}

class SeatSelectionData {
  const SeatSelectionData({
    required this.seats,
    required this.pricePerSeat,
    required this.pickupPoint,
    required this.destination,
    required this.vehicleNumber,
    required this.vehicleName,
    required this.vehicleType,
    required this.vehicleModel,
    required this.departureTime,
    required this.arrivalTime,
    required this.driverName,
    required this.driverRating,
  });

  final List<SeatOption> seats;
  final double pricePerSeat;
  final String pickupPoint;
  final String destination;
  final String vehicleNumber;
  final String vehicleName;
  final String vehicleType;
  final String vehicleModel;
  final String departureTime;
  final String arrivalTime;
  final String driverName;
  final double driverRating;

  int get availableCount => seats.where((seat) => seat.isAvailable).length;

  String get route => '$pickupPoint → $destination';
}
