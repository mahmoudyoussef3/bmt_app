enum OperationTripStatus {
  scheduled('مجدولة'),
  boarding('صعود الركاب'),
  openForBooking('مفتوحة للحجز'),
  inProgress('جارية'),
  completed('مكتملة'),
  cancelled('ملغاة');

  final String label;

  const OperationTripStatus(this.label);

  String get dbValue {
    return switch (this) {
      OperationTripStatus.inProgress => 'in_progress',
      OperationTripStatus.openForBooking => 'open_for_booking',
      _ => name,
    };
  }

  static OperationTripStatus fromString(String value) {
    return switch (value) {
      'in_progress' => OperationTripStatus.inProgress,
      'open_for_booking' => OperationTripStatus.openForBooking,
      _ => OperationTripStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OperationTripStatus.scheduled,
      ),
    };
  }
}

enum TripSeatState {
  available('متاح'),
  reserved('محجوز'),
  paid('مدفوع'),
  subscription('اشتراك'),
  blocked('محظور');

  final String label;

  const TripSeatState(this.label);

  static TripSeatState fromString(String value) {
    return TripSeatState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TripSeatState.available,
    );
  }
}

class OperationTrip {
  final String id;
  final String routeId;
  final String route;
  final List<TripRoutePoint> routePoints;
  final String driverId;
  final String driver;
  final String vehicleId;
  final String vehicle;
  final String date;
  final String departure;
  final String arrival;
  final OperationTripStatus status;
  final int capacity;
  final double ticketPrice;
  final String currency;
  final List<TripSeat> seats;
  final List<TripPassenger> passengers;
  final List<TripEvent> events;
  final List<String> notes;

  const OperationTrip({
    required this.id,
    required this.routeId,
    required this.route,
    required this.routePoints,
    required this.driverId,
    required this.driver,
    required this.vehicleId,
    required this.vehicle,
    required this.date,
    required this.departure,
    required this.arrival,
    required this.status,
    required this.capacity,
    this.ticketPrice = 0,
    this.currency = 'ج.م',
    required this.seats,
    required this.passengers,
    required this.events,
    required this.notes,
  });

  OperationTrip copyWith({
    String? id,
    String? routeId,
    String? route,
    List<TripRoutePoint>? routePoints,
    String? driverId,
    String? driver,
    String? vehicleId,
    String? vehicle,
    String? date,
    String? departure,
    String? arrival,
    OperationTripStatus? status,
    int? capacity,
    double? ticketPrice,
    String? currency,
    List<TripSeat>? seats,
    List<TripPassenger>? passengers,
    List<TripEvent>? events,
    List<String>? notes,
  }) {
    return OperationTrip(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      route: route ?? this.route,
      routePoints: routePoints ?? this.routePoints,
      driverId: driverId ?? this.driverId,
      driver: driver ?? this.driver,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      date: date ?? this.date,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      status: status ?? this.status,
      capacity: capacity ?? this.capacity,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      currency: currency ?? this.currency,
      seats: seats ?? this.seats,
      passengers: passengers ?? this.passengers,
      events: events ?? this.events,
      notes: notes ?? this.notes,
    );
  }

  List<String> get routeStops =>
      routePoints.map((point) => point.name).toList(growable: false);

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

  /// Combines [date] and [departure] into a sortable instant. Used to order
  /// trips chronologically (timeline/grouped views) regardless of status.
  DateTime? get scheduledAt {
    final day = DateTime.tryParse(date);
    if (day == null) return null;
    final parts = departure.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// A trip whose departure day has passed while it is still advertised as
  /// bookable.
  ///
  /// The client app only offers trips with `trip_date >= today`, so these are
  /// invisible to passengers no matter what the dashboard says. Nothing in the
  /// system retires them, so they linger as phantom inventory — the dashboard
  /// keeps reporting them as open until an operator completes or cancels them.
  bool isStaleBooking({DateTime? now}) {
    if (status != OperationTripStatus.openForBooking &&
        status != OperationTripStatus.scheduled) {
      return false;
    }
    final departure = DateTime.tryParse(date);
    if (departure == null) return false;
    final today = now ?? DateTime.now();
    return DateTime(
      departure.year,
      departure.month,
      departure.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
  }
}

class TripRoutePoint {
  final String id;
  final String name;
  final int order;

  const TripRoutePoint({
    required this.id,
    required this.name,
    required this.order,
  });

  TripRoutePoint copyWith({String? id, String? name, int? order}) {
    return TripRoutePoint(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
    );
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

/// What the operator actually chooses when planning a trip.
///
/// There is deliberately no vehicle and no capacity here. The office pairs each driver
/// with one bus, so naming the driver names the bus; the server resolves it from that
/// driver's active assignment and derives the trip's capacity and seat map from it.
/// Letting the planner send a vehicle of its own is how a driver ends up dispatched to
/// a bus another driver is assigned to — which is what six of the ten trips on file
/// before 20260731090000_driver_vehicle_authority actually did.
class CreateTripInput {
  final String routeId;
  final String route;
  final String driverId;
  final String driver;
  final String date;
  final String departure;
  final String arrival;
  final double ticketPrice;

  /// Package tier totals configured alongside [ticketPrice] in the planner's
  /// pricing panel. Keyed by [PackageTier.key] (`five_days`, `ten_days`,
  /// `monthly`, `three_months`). Any tier missing or <= 0 is derived from
  /// [ticketPrice] by `PackageTierPricing`, so a trip can never end up with a
  /// monthly package priced the same as a single ride.
  final Map<String, double> packageTierPrices;

  final String currency;
  final List<Map<String, String>> customStationTimes;

  const CreateTripInput({
    required this.routeId,
    required this.route,
    required this.driverId,
    required this.driver,
    required this.date,
    required this.departure,
    this.arrival = '',
    this.ticketPrice = 0,
    this.packageTierPrices = const {},
    this.currency = 'ج.م',
    this.customStationTimes = const [],
  });
}
