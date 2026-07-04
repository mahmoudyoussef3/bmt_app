import '../../domain/entities/seat_option.dart';

class SeatOptionModel {
  const SeatOptionModel({
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

  SeatOption toEntity() {
    return SeatOption(
      id: id,
      seatNumber: seatNumber,
      availability: availability,
      seatLabel: seatLabel,
      row: row,
      column: column,
    );
  }
}

class SeatSelectionModel {
  const SeatSelectionModel({
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
  final List<SeatOptionModel> seats;
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

  SeatSelectionData toEntity() {
    return SeatSelectionData(
      tripId: tripId,
      seats: seats.map((seat) => seat.toEntity()).toList(),
      pricePerSeat: pricePerSeat,
      pickupPoint: pickupPoint,
      destination: destination,
      vehicleNumber: vehicleNumber,
      vehicleName: vehicleName,
      vehicleType: vehicleType,
      vehicleModel: vehicleModel,
      tripDate: tripDate,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      driverName: driverName,
      driverRating: driverRating,
    );
  }
}
