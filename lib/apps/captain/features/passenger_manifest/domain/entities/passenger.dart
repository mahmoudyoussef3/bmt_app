/// Mirrors `trip_passengers.status`, whose check constraint allows exactly
/// `reserved | confirmed | cancelled | no_show | completed`.
///
/// There is deliberately no "late": the manifest used to offer it, but the
/// column has no value to store it in, so it was written as `reserved` — the
/// same value as [pending]. The captain saw the card flip to متأخر, and then
/// watched the realtime refresh silently flip it back. A status the backend
/// cannot hold is not a status.
enum PassengerBoardingStatus { pending, boarded, absent, cancelled }

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
