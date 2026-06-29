enum PassengerBoardingStatus { pending, boarded, absent, late, cancelled }

class Passenger {
  const Passenger({
    required this.id,
    required this.name,
    required this.seat,
    required this.pickupPoint,
    required this.destination,
    required this.pickupTime,
    required this.phone,
    this.status = PassengerBoardingStatus.pending,
  });

  final String id;
  final String name;
  final String seat;
  final String pickupPoint;
  final String destination;
  final String pickupTime;
  final String phone;
  final PassengerBoardingStatus status;

  Passenger copyWith({PassengerBoardingStatus? status}) {
    return Passenger(
      id: id,
      name: name,
      seat: seat,
      pickupPoint: pickupPoint,
      destination: destination,
      pickupTime: pickupTime,
      phone: phone,
      status: status ?? this.status,
    );
  }
}
