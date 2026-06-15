import '../../domain/entities/operation_trip.dart';

class OperationTripModel extends OperationTrip {
  const OperationTripModel({
    required super.id,
    required super.routeId,
    required super.route,
    required super.routePoints,
    required super.driverId,
    required super.driver,
    required super.vehicleId,
    required super.vehicle,
    required super.date,
    required super.departure,
    required super.arrival,
    required super.status,
    required super.capacity,
    super.ticketPrice,
    super.currency,
    required super.seats,
    required super.passengers,
    required super.events,
    required super.notes,
  });

  factory OperationTripModel.fromEntity(OperationTrip trip) {
    return OperationTripModel(
      id: trip.id,
      routeId: trip.routeId,
      route: trip.route,
      routePoints: trip.routePoints,
      driverId: trip.driverId,
      driver: trip.driver,
      vehicleId: trip.vehicleId,
      vehicle: trip.vehicle,
      date: trip.date,
      departure: trip.departure,
      arrival: trip.arrival,
      status: trip.status,
      capacity: trip.capacity,
      ticketPrice: trip.ticketPrice,
      currency: trip.currency,
      seats: trip.seats,
      passengers: trip.passengers,
      events: trip.events,
      notes: trip.notes,
    );
  }

  factory OperationTripModel.fromJson(Map<String, dynamic> json) {
    // Parse route name from joined operation_routes
    final routeMap = json['route'] as Map<String, dynamic>?;
    final routeName = routeMap?['name'] as String? ?? 'مسار غير معروف';

    // Parse driver name from joined drivers
    final driverMap = json['driver'] as Map<String, dynamic>?;
    final driverName = driverMap?['full_name'] as String? ?? 'سائق غير معروف';

    // Parse vehicle name/plate from joined vehicles
    final vehicleMap = json['vehicle'] as Map<String, dynamic>?;
    final vehiclePlate = vehicleMap?['plate_number'] as String? ?? '';
    final vehicleCode = vehicleMap?['vehicle_code'] as String? ?? '';
    final vehicleType = vehicleMap?['vehicle_type'] as String? ?? '';
    final vehicleName = vehicleCode.isNotEmpty
        ? '$vehicleType ($vehicleCode) $vehiclePlate'
        : vehiclePlate;

    // Parse sublists
    final pointsList =
        (json['route_points'] as List?)
            ?.map(
              (p) => TripRoutePointModel.fromJson(p as Map<String, dynamic>),
            )
            .toList() ??
        [];
    pointsList.sort((a, b) => a.order.compareTo(b.order));

    final seatsList =
        (json['seats'] as List?)
            ?.map((s) => TripSeatModel.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    seatsList.sort((a, b) => a.label.compareTo(b.label));

    final passengersList =
        (json['passengers'] as List?)
            ?.map((p) => TripPassengerModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    final eventsList =
        (json['events'] as List?)
            ?.map((e) => TripEventModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse notes array
    final rawNotes = json['notes'] as List?;
    final notesList = rawNotes?.map((n) => n.toString()).toList() ?? [];

    return OperationTripModel(
      id: json['id'] as String? ?? '',
      routeId: json['route_id'] as String? ?? '',
      route: routeName,
      routePoints: pointsList,
      driverId: json['driver_id'] as String? ?? '',
      driver: driverName,
      vehicleId: json['vehicle_id'] as String? ?? '',
      vehicle: vehicleName,
      date: json['trip_date'] as String? ?? '',
      departure: json['departure_time'] as String? ?? '',
      arrival: json['arrival_time'] as String? ?? '',
      status: OperationTripStatus.fromString(
        json['status'] as String? ?? 'scheduled',
      ),
      capacity: json['capacity'] as int? ?? 0,
      ticketPrice: (json['ticket_price'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'ج.م',
      seats: seatsList,
      passengers: passengersList,
      events: eventsList,
      notes: notesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'trip_date': date,
      'departure_time': departure,
      'arrival_time': arrival.isEmpty ? null : arrival,
      'status': status.dbValue,
      'capacity': capacity,
      'ticket_price': ticketPrice,
      'currency': currency,
      'notes': notes,
    };
  }
}

class TripRoutePointModel extends TripRoutePoint {
  const TripRoutePointModel({
    required super.id,
    required super.name,
    required super.order,
  });

  factory TripRoutePointModel.fromJson(Map<String, dynamic> json) {
    return TripRoutePointModel(
      id: json['id'] as String? ?? '',
      name: json['point_name'] as String? ?? '',
      order: json['point_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson(String tripId) {
    return {'trip_id': tripId, 'point_name': name, 'point_order': order};
  }
}

class TripSeatModel extends TripSeat {
  const TripSeatModel({
    required super.id,
    required super.label,
    required super.row,
    required super.column,
    required super.state,
    super.passengerId,
    required super.notes,
  });

  factory TripSeatModel.fromJson(Map<String, dynamic> json) {
    return TripSeatModel(
      id: json['id'] as String? ?? '',
      label: json['seat_label'] as String? ?? '',
      row: json['seat_row'] as int? ?? 0,
      column: json['seat_column'] as int? ?? 0,
      state: TripSeatState.fromString(json['state'] as String? ?? 'available'),
      passengerId: json['passenger_id'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson(String tripId) {
    return {
      'trip_id': tripId,
      'seat_label': label,
      'seat_row': row,
      'seat_column': column,
      'state': state.name,
      'passenger_id': passengerId,
      'notes': notes,
    };
  }
}

class TripPassengerModel extends TripPassenger {
  const TripPassengerModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.seat,
    required super.pickup,
    required super.dropoff,
    required super.paymentMethod,
    required super.status,
  });

  factory TripPassengerModel.fromJson(Map<String, dynamic> json) {
    return TripPassengerModel(
      id: json['id'] as String? ?? '',
      name: json['passenger_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      seat: json['seat_label'] as String? ?? '',
      pickup: json['pickup_point_name'] as String? ?? '',
      dropoff: json['dropoff_point_name'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      status: json['status'] as String? ?? 'reserved',
    );
  }
}

class TripEventModel extends TripEvent {
  const TripEventModel({
    required super.title,
    required super.time,
    required super.description,
    required super.done,
  });

  factory TripEventModel.fromJson(Map<String, dynamic> json) {
    final eventTime = json['event_time'] != null
        ? DateTime.parse(json['event_time'] as String).toLocal()
        : DateTime.now();
    final timeStr =
        '${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}';
    return TripEventModel(
      title: json['title'] as String? ?? '',
      time: timeStr,
      description: json['description'] as String? ?? '',
      done: json['done'] as bool? ?? true,
    );
  }
}
