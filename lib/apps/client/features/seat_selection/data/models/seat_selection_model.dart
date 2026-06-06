import '../../domain/entities/seat_option.dart';

class SeatOptionModel {
  const SeatOptionModel({required this.id, required this.availability});

  final String id;
  final SeatAvailability availability;

  SeatOption toEntity() {
    return SeatOption(id: id, availability: availability);
  }
}

class SeatSelectionModel {
  const SeatSelectionModel({
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

  final List<SeatOptionModel> seats;
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

  SeatSelectionData toEntity() {
    return SeatSelectionData(
      seats: seats.map((seat) => seat.toEntity()).toList(),
      pricePerSeat: pricePerSeat,
      pickupPoint: pickupPoint,
      destination: destination,
      vehicleNumber: vehicleNumber,
      vehicleName: vehicleName,
      vehicleType: vehicleType,
      vehicleModel: vehicleModel,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      driverName: driverName,
      driverRating: driverRating,
    );
  }
}
