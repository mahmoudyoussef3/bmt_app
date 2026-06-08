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

enum TripSeatState {
  available('متاح'),
  reserved('محجوز'),
  confirmed('مؤكد'),
  blocked('محظور');

  final String label;

  const TripSeatState(this.label);
}

class OperationTrip {
  final String id;
  final String route;
  final String driver;
  final String vehicle;
  final String date;
  final String departure;
  final String arrival;
  final OperationTripStatus status;
  final List<TripSeat> seats;
  final List<TripPassenger> passengers;
  final List<TripPayment> payments;
  final List<TripEvent> events;
  final List<String> notes;

  const OperationTrip({
    required this.id,
    required this.route,
    required this.driver,
    required this.vehicle,
    required this.date,
    required this.departure,
    required this.arrival,
    required this.status,
    required this.seats,
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
    String? date,
    String? departure,
    String? arrival,
    OperationTripStatus? status,
    List<TripSeat>? seats,
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
      date: date ?? this.date,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      status: status ?? this.status,
      seats: seats ?? this.seats,
      passengers: passengers ?? this.passengers,
      payments: payments ?? this.payments,
      events: events ?? this.events,
      notes: notes ?? this.notes,
    );
  }

  int get totalSeats => seats.length;

  int get availableSeats {
    return seats.where((seat) => seat.state == TripSeatState.available).length;
  }

  int get reservedSeats {
    return seats.where((seat) => seat.state == TripSeatState.reserved).length;
  }

  int get occupiedSeats {
    return seats.where((seat) => seat.state == TripSeatState.confirmed).length;
  }

  int get blockedSeats {
    return seats.where((seat) => seat.state == TripSeatState.blocked).length;
  }

  int get passengersCount => reservedSeats + occupiedSeats;
}

class TripSeat {
  final String id;
  final String label;
  final int row;
  final int column;
  final TripSeatState state;
  final String? passengerName;
  final String? pickup;
  final String notes;

  const TripSeat({
    required this.id,
    required this.label,
    required this.row,
    required this.column,
    required this.state,
    this.passengerName,
    this.pickup,
    this.notes = '',
  });

  TripSeat copyWith({
    String? id,
    String? label,
    int? row,
    int? column,
    TripSeatState? state,
    String? passengerName,
    bool clearPassengerName = false,
    String? pickup,
    bool clearPickup = false,
    String? notes,
  }) {
    return TripSeat(
      id: id ?? this.id,
      label: label ?? this.label,
      row: row ?? this.row,
      column: column ?? this.column,
      state: state ?? this.state,
      passengerName: clearPassengerName
          ? null
          : passengerName ?? this.passengerName,
      pickup: clearPickup ? null : pickup ?? this.pickup,
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
