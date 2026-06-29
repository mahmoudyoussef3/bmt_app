import '../../domain/entities/passenger.dart';

class PassengerModel {
  const PassengerModel({
    required this.id,
    required this.name,
    required this.seat,
    required this.pickupPoint,
    required this.destination,
    required this.pickupTime,
    required this.phone,
    required this.status,
  });

  final String id;
  final String name;
  final String seat;
  final String pickupPoint;
  final String destination;
  final String pickupTime;
  final String phone;
  final PassengerBoardingStatus status;

  Passenger toEntity() {
    return Passenger(
      id: id,
      name: name,
      seat: seat,
      pickupPoint: pickupPoint,
      destination: destination,
      pickupTime: pickupTime,
      phone: phone,
      status: status,
    );
  }
}
