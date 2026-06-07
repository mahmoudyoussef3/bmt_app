enum OperationTripStatus {
  scheduled('مجدولة'),
  ready('جاهزة'),
  waiting('في الانتظار'),
  inProgress('قيد التنفيذ'),
  completed('مكتملة'),
  cancelled('ملغاة');

  final String label;

  const OperationTripStatus(this.label);
}

class OperationTrip {
  final String id;
  final String route;
  final String driver;
  final String vehicle;
  final int passengersCount;
  final String departure;
  final String arrival;
  final OperationTripStatus status;
  final List<TripPassenger> passengers;
  final List<TripPayment> payments;
  final List<TripEvent> events;
  final List<String> notes;

  const OperationTrip({
    required this.id,
    required this.route,
    required this.driver,
    required this.vehicle,
    required this.passengersCount,
    required this.departure,
    required this.arrival,
    required this.status,
    required this.passengers,
    required this.payments,
    required this.events,
    required this.notes,
  });

  OperationTrip copyWith({
    String? id,
    String? route,
    String? driver,
    String? vehicle,
    int? passengersCount,
    String? departure,
    String? arrival,
    OperationTripStatus? status,
    List<TripPassenger>? passengers,
    List<TripPayment>? payments,
    List<TripEvent>? events,
    List<String>? notes,
  }) {
    return OperationTrip(
      id: id ?? this.id,
      route: route ?? this.route,
      driver: driver ?? this.driver,
      vehicle: vehicle ?? this.vehicle,
      passengersCount: passengersCount ?? this.passengersCount,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      status: status ?? this.status,
      passengers: passengers ?? this.passengers,
      payments: payments ?? this.payments,
      events: events ?? this.events,
      notes: notes ?? this.notes,
    );
  }
}

class TripPassenger {
  final String name;
  final String seat;
  final String pickup;
  final String status;

  const TripPassenger({
    required this.name,
    required this.seat,
    required this.pickup,
    required this.status,
  });
}

class TripPayment {
  final String passengerName;
  final String amount;
  final String method;
  final String status;

  const TripPayment({
    required this.passengerName,
    required this.amount,
    required this.method,
    required this.status,
  });
}

class TripEvent {
  final String title;
  final String time;
  final String description;
  final bool done;

  const TripEvent({
    required this.title,
    required this.time,
    required this.description,
    required this.done,
  });
}
