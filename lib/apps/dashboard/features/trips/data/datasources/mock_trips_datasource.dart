import '../../domain/entities/operation_trip.dart';
import '../../domain/entities/trip_pricing.dart';
import '../models/operation_trip_model.dart';
import '../models/trip_pricing_model.dart';

abstract class TripsDatasource {
  Future<List<OperationTripModel>> fetchTrips();
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  );
  Future<OperationTripModel> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  );
  Future<OperationTripModel> createTrip(CreateTripInput input);
  Future<OperationTripModel> updateTripInfo(OperationTrip trip);
  Future<OperationTripModel> updatePassenger(
    String tripId,
    TripPassenger passenger,
  );
  Future<OperationTripModel> cancelPassenger(String tripId, String passengerId);
  Future<OperationTripModel> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  );
  Future<List<TripPricingModel>> fetchTripPricing(String tripId);
  Future<TripPricingModel> upsertTripPricing(TripPricing pricing);
  Future<TripPricingModel> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  );
}

class MockTripsDatasource implements TripsDatasource {
  final List<OperationTripModel> _trips = _buildTrips();
  late final List<TripPricingModel> _pricing = _buildTripPricing(_trips);

  @override
  Future<List<OperationTripModel>> fetchTrips() async {
    return List<OperationTripModel>.unmodifiable(_trips);
  }

  @override
  Future<OperationTripModel> createTrip(CreateTripInput input) async {
    if (input.route.trim().isEmpty ||
        input.driver.trim().isEmpty ||
        input.vehicle.trim().isEmpty ||
        input.capacity <= 0) {
      throw ArgumentError('Trip requires route, driver, vehicle, and capacity');
    }
    final points = _pointsFor(input.route);
    final trip = OperationTripModel(
      id: 'TR-${1000 + _trips.length + 1}',
      route: input.route,
      routePoints: points,
      driver: input.driver,
      vehicle: input.vehicle,
      date: input.date,
      departure: input.departure,
      arrival: _arrivalFrom(input.departure),
      status: OperationTripStatus.scheduled,
      capacity: input.capacity,
      seats: _seatMap(input.capacity, 0, 'TR-${1000 + _trips.length + 1}'),
      passengers: const [],
      events: const [
        TripEvent(
          title: 'تم إنشاء الرحلة',
          time: 'الآن',
          description: 'تم إنشاء الرحلة بعد اختيار المسار والسائق والمركبة.',
          done: true,
        ),
      ],
      notes: ['تم تحميل محطات المسار تلقائياً'],
    );
    _trips.insert(0, trip);
    return trip;
  }

  @override
  Future<OperationTripModel> updateTripInfo(OperationTrip trip) async {
    _ensureValidTrip(trip);
    return _replace(
      trip.copyWith(
        routePoints: _pointsFor(trip.route),
        events: [
          const TripEvent(
            title: 'تم تعديل معلومات الرحلة',
            time: 'الآن',
            description: 'تم تحديث بيانات الرحلة من مساحة التشغيل.',
            done: true,
          ),
          ...trip.events,
        ],
      ),
    );
  }

  @override
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  ) async {
    final existing = _find(tripId);
    return _replace(
      existing.copyWith(
        status: status,
        events: [
          TripEvent(
            title: 'تم تحديث الحالة',
            time: 'الآن',
            description: 'تم نقل الرحلة إلى ${status.label}',
            done: true,
          ),
          ...existing.events,
        ],
      ),
    );
  }

  @override
  Future<OperationTripModel> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) async {
    final trip = _find(tripId);
    final seats = trip.seats.map((seat) {
      if (seat.id != seatId) return seat;
      return seat.copyWith(
        state: state,
        clearPassenger:
            state == TripSeatState.available || state == TripSeatState.blocked,
        notes: state == TripSeatState.blocked
            ? 'محظور بواسطة خدمة العملاء'
            : seat.notes,
      );
    }).toList();
    final updatedSeat = seats.firstWhere((seat) => seat.id == seatId);
    return _replace(
      trip.copyWith(
        seats: seats,
        events: [
          TripEvent(
            title: 'تم تعديل مقعد',
            time: 'الآن',
            description:
                'تم تحديث المقعد ${updatedSeat.label} إلى ${updatedSeat.state.label}.',
            done: true,
          ),
          ...trip.events,
        ],
      ),
    );
  }

  @override
  Future<OperationTripModel> updatePassenger(
    String tripId,
    TripPassenger passenger,
  ) async {
    final trip = _find(tripId);
    final passengers = trip.passengers
        .map((item) => item.id == passenger.id ? passenger : item)
        .toList();
    final seats = trip.seats.map((seat) {
      if (seat.passengerId != passenger.id) return seat;
      return seat.copyWith(label: passenger.seat);
    }).toList();
    return _replace(
      trip.copyWith(
        passengers: passengers,
        seats: seats,
        events: [
          TripEvent(
            title: 'تم تعديل راكب',
            time: 'الآن',
            description: 'تم تعديل بيانات ${passenger.name}.',
            done: true,
          ),
          ...trip.events,
        ],
      ),
    );
  }

  @override
  Future<OperationTripModel> cancelPassenger(
    String tripId,
    String passengerId,
  ) async {
    final trip = _find(tripId);
    final passenger = trip.passengers.firstWhere(
      (item) => item.id == passengerId,
    );
    final passengers = trip.passengers
        .map(
          (item) =>
              item.id == passengerId ? item.copyWith(status: 'ملغي') : item,
        )
        .toList();
    final seats = trip.seats
        .map(
          (seat) => seat.passengerId == passengerId
              ? seat.copyWith(
                  state: TripSeatState.available,
                  clearPassenger: true,
                )
              : seat,
        )
        .toList();
    return _replace(
      trip.copyWith(
        passengers: passengers,
        seats: seats,
        events: [
          TripEvent(
            title: 'تم إلغاء حجز',
            time: 'الآن',
            description: 'تم إلغاء حجز ${passenger.name}.',
            done: true,
          ),
          ...trip.events,
        ],
      ),
    );
  }

  @override
  Future<OperationTripModel> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  ) async {
    final trip = _find(tripId);
    final target = trip.seats.firstWhere((seat) => seat.label == seatLabel);
    if (target.state != TripSeatState.available) {
      throw ArgumentError('Seat is not available');
    }
    final passenger = trip.passengers.firstWhere(
      (item) => item.id == passengerId,
    );
    final oldSeat = passenger.seat;
    final passengers = trip.passengers
        .map(
          (item) =>
              item.id == passengerId ? item.copyWith(seat: seatLabel) : item,
        )
        .toList();
    final seats = trip.seats.map((seat) {
      if (seat.passengerId == passengerId) {
        return seat.copyWith(
          state: TripSeatState.available,
          clearPassenger: true,
        );
      }
      if (seat.label == seatLabel) {
        return seat.copyWith(
          state: passenger.status == 'اشتراك'
              ? TripSeatState.subscription
              : TripSeatState.reserved,
          passengerId: passengerId,
        );
      }
      return seat;
    }).toList();
    return _replace(
      trip.copyWith(
        passengers: passengers,
        seats: seats,
        events: [
          TripEvent(
            title: 'تم نقل راكب',
            time: 'الآن',
            description:
                'تم نقل ${passenger.name} من مقعد $oldSeat إلى $seatLabel.',
            done: true,
          ),
          ...trip.events,
        ],
      ),
    );
  }

  @override
  Future<List<TripPricingModel>> fetchTripPricing(String tripId) async {
    _find(tripId);
    return List<TripPricingModel>.unmodifiable(
      _pricing.where((pricing) => pricing.tripId == tripId).toList()
        ..sort((a, b) {
          final fromOrder = a.fromPointOrder.compareTo(b.fromPointOrder);
          if (fromOrder != 0) return fromOrder;
          return a.toPointOrder.compareTo(b.toPointOrder);
        }),
    );
  }

  @override
  Future<TripPricingModel> upsertTripPricing(TripPricing pricing) async {
    _validatePricing(pricing);
    final now = DateTime.now();
    final index = _pricing.indexWhere((item) => item.id == pricing.id);
    final model = TripPricingModel.fromEntity(
      pricing.copyWith(
        id: pricing.id.trim().isEmpty
            ? 'price-${pricing.tripId}-${_pricing.length + 1}'
            : pricing.id,
        createdAt: index == -1 ? now : _pricing[index].createdAt,
        updatedAt: now,
      ),
    );
    if (index == -1) {
      _pricing.add(model);
    } else {
      _pricing[index] = model;
    }
    return model;
  }

  @override
  Future<TripPricingModel> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  ) async {
    final index = _pricing.indexWhere((item) => item.id == pricingId);
    if (index == -1) throw ArgumentError('Trip pricing not found');
    final updated = TripPricingModel.fromEntity(
      _pricing[index].copyWith(isActive: isActive, updatedAt: DateTime.now()),
    );
    _pricing[index] = updated;
    return updated;
  }

  OperationTripModel _find(String tripId) {
    return _trips.firstWhere(
      (trip) => trip.id == tripId,
      orElse: () => throw ArgumentError('Trip not found'),
    );
  }

  OperationTripModel _replace(OperationTrip trip) {
    _ensureValidTrip(trip);
    final index = _trips.indexWhere((item) => item.id == trip.id);
    if (index == -1) throw ArgumentError('Trip not found');
    final model = OperationTripModel.fromEntity(trip);
    _trips[index] = model;
    return model;
  }

  void _ensureValidTrip(OperationTrip trip) {
    if (trip.route.trim().isEmpty ||
        trip.driver.trim().isEmpty ||
        trip.vehicle.trim().isEmpty ||
        trip.capacity <= 0) {
      throw ArgumentError('Trip requires route, driver, vehicle, and capacity');
    }
  }

  void _validatePricing(TripPricing pricing) {
    _find(pricing.tripId);
    if (pricing.tripId.trim().isEmpty ||
        pricing.currency.trim().isEmpty ||
        pricing.fromPointId == pricing.toPointId ||
        pricing.fromPointOrder >= pricing.toPointOrder ||
        pricing.oneTimePrice <= 0 ||
        pricing.fiveDaysPrice <= 0 ||
        pricing.tenDaysPrice <= 0 ||
        pricing.monthlyPrice <= 0 ||
        pricing.threeMonthsPrice <= 0) {
      throw ArgumentError('Invalid trip pricing');
    }
  }
}

List<OperationTripModel> _buildTrips() {
  final routes = _routeStops.keys.toList();
  final drivers = [
    'أحمد عبد الرازق',
    'مصطفى سمير',
    'كريم فتحي',
    'محمد سامي',
    'حسن عادل',
    'طارق محمود',
    'وليد نبيل',
    'إسلام حسين',
  ];
  final vehicles = [
    'كوستر ٣٣٤٥ ق ل',
    'سبرنتر ٧٢١٨ م ن',
    'هايس ١٥٥٢ ج ب',
    'H1 ٩٠٢١ ص ج',
    'روزا ٧١١٨ م ن',
  ];
  final statuses = OperationTripStatus.values;
  return List.generate(50, (index) {
    final route = routes[index % routes.length];
    final capacity = [12, 14, 19, 28][index % 4];
    final booked = (capacity * ([.35, .55, .75, .9][index % 4])).floor();
    final id = 'TR-${1001 + index}';
    final seats = _seatMap(capacity, booked, id);
    return OperationTripModel(
      id: id,
      route: route,
      routePoints: _pointsFor(route),
      driver: drivers[index % drivers.length],
      vehicle: vehicles[index % vehicles.length],
      date: index < 20 ? '٨ يونيو ٢٠٢٦' : '${9 + (index % 12)} يونيو ٢٠٢٦',
      departure: '${7 + (index % 10)}:${index.isEven ? '٠٠' : '٣٠'}',
      arrival: '${8 + (index % 10)}:${index.isEven ? '١٥' : '٤٥'}',
      status: statuses[index % statuses.length],
      capacity: capacity,
      seats: seats,
      passengers: _passengersFromSeats(seats, route, id),
      events: _events(index),
      notes: [
        'محطات المسار محملة تلقائياً',
        'الرحلة مكتملة البيانات التشغيلية',
      ],
    );
  });
}

List<TripSeat> _seatMap(int total, int booked, String tripId) {
  return List.generate(total, (index) {
    final number = index + 1;
    final state = number > booked
        ? TripSeatState.available
        : number % 9 == 0
        ? TripSeatState.blocked
        : number % 5 == 0
        ? TripSeatState.subscription
        : number % 3 == 0
        ? TripSeatState.paid
        : TripSeatState.reserved;
    final occupied =
        state == TripSeatState.reserved ||
        state == TripSeatState.paid ||
        state == TripSeatState.subscription;
    return TripSeat(
      id: '$tripId-seat-$number',
      label: '$number',
      row: index ~/ 4,
      column: index % 4,
      state: state,
      passengerId: occupied ? '$tripId-passenger-$number' : null,
      notes: state == TripSeatState.blocked ? 'مقعد محظور للتشغيل' : '',
    );
  });
}

List<TripPassenger> _passengersFromSeats(
  List<TripSeat> seats,
  String route,
  String tripId,
) {
  final stops = _stopsFor(route);
  return seats.where((seat) => seat.passengerId != null).map((seat) {
    final number = int.parse(seat.label);
    return TripPassenger(
      id: seat.passengerId!,
      name: _names[number % _names.length],
      phone: '010${22334455 + number * 713}',
      seat: seat.label,
      pickup: stops[number % (stops.length - 1)],
      dropoff: stops.last,
      paymentMethod: seat.state == TripSeatState.subscription
          ? 'اشتراك'
          : number.isEven
          ? 'إنستاباي'
          : 'فودافون كاش',
      status: seat.state == TripSeatState.paid
          ? 'مدفوع'
          : seat.state == TripSeatState.subscription
          ? 'اشتراك'
          : 'محجوز',
    );
  }).toList();
}

List<TripEvent> _events(int index) {
  return [
    const TripEvent(
      title: 'تم إنشاء الرحلة',
      time: '٧:١٠',
      description: 'تم إنشاء الرحلة من جدول التشغيل.',
      done: true,
    ),
    const TripEvent(
      title: 'تم تعيين السائق',
      time: '٧:١٥',
      description: 'تم ربط السائق والمركبة بالرحلة.',
      done: true,
    ),
    if (index % 2 == 0)
      const TripEvent(
        title: 'تم إضافة راكب',
        time: '٧:٤٠',
        description: 'تم إضافة راكب من خدمة العملاء.',
        done: true,
      ),
    if (index % 5 == 0)
      const TripEvent(
        title: 'تم إلغاء حجز',
        time: '٨:٠٥',
        description: 'تم إلغاء حجز بناءً على طلب العميل.',
        done: true,
      ),
    if (index % 3 == 0)
      const TripEvent(
        title: 'تم بدء الرحلة',
        time: '٨:٣٠',
        description: 'السائق بدأ الرحلة من نقطة الانطلاق.',
        done: true,
      ),
  ];
}

String _arrivalFrom(String departure) => '$departure + ٧٥ دقيقة';

List<String> _stopsFor(String route) {
  return _routeStops[route] ?? _routeStops.values.first;
}

List<TripRoutePoint> _pointsFor(String route) {
  final stops = _stopsFor(route);
  return stops.indexed.map((entry) {
    final (index, stop) = entry;
    return TripRoutePoint(
      id: '${_routeSlug(route)}-point-${index + 1}',
      name: stop,
      order: index + 1,
    );
  }).toList();
}

String _routeSlug(String route) {
  return 'route-${_routeStops.keys.toList().indexOf(route) + 1}';
}

List<TripPricingModel> _buildTripPricing(List<OperationTripModel> trips) {
  return trips.take(12).expand((trip) {
    final points = trip.routePoints;
    final first = points.first;
    final middle = points[points.length ~/ 2];
    final beforeLast = points[points.length - 2];
    final last = points.last;
    return [
      _pricing(
        id: '${trip.id}-price-1',
        tripId: trip.id,
        from: first,
        to: last,
        oneTime: 120,
        fiveDays: 550,
        tenDays: 1000,
        monthly: 1900,
        threeMonths: 5200,
      ),
      _pricing(
        id: '${trip.id}-price-2',
        tripId: trip.id,
        from: first,
        to: middle,
        oneTime: 60,
        fiveDays: 280,
        tenDays: 520,
        monthly: 950,
        threeMonths: 2600,
      ),
      _pricing(
        id: '${trip.id}-price-3',
        tripId: trip.id,
        from: middle,
        to: beforeLast.order > middle.order ? beforeLast : last,
        oneTime: 35,
        fiveDays: 170,
        tenDays: 320,
        monthly: 600,
        threeMonths: 1700,
      ),
    ];
  }).toList();
}

TripPricingModel _pricing({
  required String id,
  required String tripId,
  required TripRoutePoint from,
  required TripRoutePoint to,
  required double oneTime,
  required double fiveDays,
  required double tenDays,
  required double monthly,
  required double threeMonths,
}) {
  final createdAt = DateTime(2026, 6, 1, 9);
  return TripPricingModel(
    id: id,
    tripId: tripId,
    fromPointId: from.id,
    toPointId: to.id,
    fromPointName: from.name,
    toPointName: to.name,
    fromPointOrder: from.order,
    toPointOrder: to.order,
    oneTimePrice: oneTime,
    fiveDaysPrice: fiveDays,
    tenDaysPrice: tenDays,
    monthlyPrice: monthly,
    threeMonthsPrice: threeMonths,
    currency: 'ج.م',
    isActive: true,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

const _routeStops = {
  'بنها - القرية الذكية': [
    'بنها',
    'طوخ',
    'شبرا',
    'رمسيس',
    'الشيخ زايد',
    'القرية الذكية',
  ],
  'المنصورة - القاهرة الجديدة': [
    'المنصورة',
    'طلخا',
    'ميت غمر',
    'بنها',
    'الرحاب',
    'التجمع الخامس',
  ],
  'مدينة نصر - القرية الذكية': [
    'عباس العقاد',
    'مصر الجديدة',
    'رمسيس',
    'المحور',
    'القرية الذكية',
  ],
  'المعادي - العاصمة الإدارية': [
    'المعادي',
    'زهراء المعادي',
    'القطامية',
    'التجمع الثالث',
    'العاصمة الإدارية',
  ],
  'الشروق - التجمع الخامس': [
    'الشروق',
    'مدينتي',
    'الرحاب',
    'كايرو فيستيفال',
    'التجمع الخامس',
  ],
};

const _names = [
  'سارة أحمد',
  'خالد محمود',
  'رنا يوسف',
  'محمود علي',
  'ياسمين علي',
  'محمد سمير',
  'ندى هشام',
  'أحمد سامي',
  'هبة عادل',
  'كريم عادل',
  'منة طارق',
  'عمر وليد',
];
