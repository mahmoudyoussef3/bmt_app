enum SeatAvailability { available, reserved }

class SeatOption {
  const SeatOption({
    required this.id,
    required this.seatNumber,
    required this.availability,
    this.seatLabel = '',
    this.row = 0,
    this.column = 0,
  });

  final String id;
  final int seatNumber;
  final SeatAvailability availability;
  final String seatLabel;
  final int row;
  final int column;

  bool get isAvailable => availability == SeatAvailability.available;
  String get displayLabel =>
      seatLabel.trim().isEmpty ? '$seatNumber' : seatLabel.trim();
}

class SeatSelectionData {
  const SeatSelectionData({
    required this.tripId,
    required this.seats,
    required this.pricePerSeat,
    required this.pickupPoint,
    required this.destination,
    required this.vehicleNumber,
    required this.vehicleName,
    required this.vehicleType,
    required this.vehicleModel,
    required this.tripDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.driverName,
    required this.driverRating,
  });

  final String tripId;
  final List<SeatOption> seats;
  final double pricePerSeat;
  final String pickupPoint;
  final String destination;
  final String vehicleNumber;
  final String vehicleName;
  final String vehicleType;
  final String vehicleModel;
  final String tripDate;
  final String departureTime;
  final String arrivalTime;
  final String driverName;
  final double driverRating;

  int get availableCount => seats.where((seat) => seat.isAvailable).length;

  String get route => '$pickupPoint → $destination';
}
