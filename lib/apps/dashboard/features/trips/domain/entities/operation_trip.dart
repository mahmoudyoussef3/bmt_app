enum OperationTripStatus {
  scheduled('مجدولة'),
  openForBooking('مفتوحة للحجز'),
  inProgress('جارية'),
  completed('مكتملة'),
  cancelled('ملغاة');

  final String label;

  const OperationTripStatus(this.label);
}

enum TripSeatState {
  available('متاح'),
  reserved('محجوز'),
  paid('مدفوع'),
  subscription('اشتراك'),
  blocked('محظور');

  final String label;

  const TripSeatState(this.label);
}

class OperationTrip {
  final String id;
  final String route;
  final List<String> routeStops;
  final String driver;
  final String vehicle;
  final String date;
  final String departure;
  final String arrival;
  final OperationTripStatus status;
  final int capacity;
  final List<TripSeat> seats;
  final List<TripPassenger> passengers;
  final List<TripEvent> events;
  final List<String> notes;

  const OperationTrip({
    required this.id,
    required this.route,
    required this.routeStops,
    required this.driver,
    required this.vehicle,
    required this.date,
    required this.departure,
    required this.arrival,
    required this.status,
    required this.capacity,
    required this.seats,
    required this.passengers,
    required this.events,
    required this.notes,
  });

  OperationTrip copyWith({
    String? id,
    String? route,
    List<String>? routeStops,
    String? driver,
    String? vehicle,
    String? date,
    String? departure,
    String? arrival,
    OperationTripStatus? status,
    int? capacity,
    List<TripSeat>? seats,
    List<TripPassenger>? passengers,
    List<TripEvent>? events,
    List<String>? notes,
  }) {
    return OperationTrip(
      id: id ?? this.id,
      route: route ?? this.route,
      routeStops: routeStops ?? this.routeStops,
      driver: driver ?? this.driver,
      vehicle: vehicle ?? this.vehicle,
      date: date ?? this.date,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      status: status ?? this.status,
      capacity: capacity ?? this.capacity,
      seats: seats ?? this.seats,
      passengers: passengers ?? this.passengers,
      events: events ?? this.events,
      notes: notes ?? this.notes,
    );
  }

  int get bookedSeats {
    return seats
        .where(
          (seat) =>
              seat.state == TripSeatState.reserved ||
              seat.state == TripSeatState.paid ||
              seat.state == TripSeatState.subscription,
        )
        .length;
  }

  int get availableSeats {
    return seats.where((seat) => seat.state == TripSeatState.available).length;
  }

  int get blockedSeats {
    return seats.where((seat) => seat.state == TripSeatState.blocked).length;
  }
}

class TripSeat {
  final String id;
  final String label;
  final int row;
  final int column;
  final TripSeatState state;
  final String? passengerId;
  final String notes;

  const TripSeat({
    required this.id,
    required this.label,
    required this.row,
    required this.column,
    required this.state,
    this.passengerId,
    this.notes = '',
  });

  TripSeat copyWith({
    String? id,
    String? label,
    int? row,
    int? column,
    TripSeatState? state,
    String? passengerId,
    bool clearPassenger = false,
    String? notes,
  }) {
    return TripSeat(
      id: id ?? this.id,
      label: label ?? this.label,
      row: row ?? this.row,
      column: column ?? this.column,
      state: state ?? this.state,
      passengerId: clearPassenger ? null : passengerId ?? this.passengerId,
      notes: notes ?? this.notes,
    );
  }
}

class TripPassenger {
  final String id;
  final String name;
  final String phone;
  final String seat;
  final String pickup;
  final String dropoff;
  final String paymentMethod;
  final String status;

  const TripPassenger({
    required this.id,
    required this.name,
    required this.phone,
    required this.seat,
    required this.pickup,
    required this.dropoff,
    required this.paymentMethod,
    required this.status,
  });

  TripPassenger copyWith({
    String? id,
    String? name,
    String? phone,
    String? seat,
    String? pickup,
    String? dropoff,
    String? paymentMethod,
    String? status,
  }) {
    return TripPassenger(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      seat: seat ?? this.seat,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
    );
  }
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

class CreateTripInput {
  final String route;
  final String driver;
  final String vehicle;
  final String date;
  final String departure;
  final int capacity;

  const CreateTripInput({
    required this.route,
    required this.driver,
    required this.vehicle,
    required this.date,
    required this.departure,
    required this.capacity,
  });
}
