enum PassengerStatus { pending, arrived, boarded, skipped, cancelled }

class Passenger {
  final String id;
  final String name;
  final String seat;
  final String pickupPoint;
  final String destination;
  final String pickupTime;
  final String phone;
  PassengerStatus status;

  Passenger({
    required this.id,
    required this.name,
    required this.seat,
    required this.pickupPoint,
    required this.destination,
    required this.pickupTime,
    required this.phone,
    this.status = PassengerStatus.pending,
  });
}
