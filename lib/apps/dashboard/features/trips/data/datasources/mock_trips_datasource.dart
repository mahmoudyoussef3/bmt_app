import '../../domain/entities/operation_trip.dart';
import '../models/operation_trip_model.dart';

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
}

class MockTripsDatasource implements TripsDatasource {
  final List<OperationTripModel> _trips = List<OperationTripModel>.from(
    _seedTrips,
  );

  @override
  Future<List<OperationTripModel>> fetchTrips() async {
    return List<OperationTripModel>.unmodifiable(_trips);
  }

  @override
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  ) async {
    final index = _trips.indexWhere((trip) => trip.id == tripId);
    if (index == -1) throw ArgumentError('Trip not found');
    final existing = _trips[index];
    final event = TripEvent(
      title: 'تحديث الحالة',
      time: 'الآن',
      description: 'تم نقل الرحلة إلى ${status.label}',
      done: true,
    );
    final updated = OperationTripModel.fromEntity(
      existing.copyWith(status: status, events: [event, ...existing.events]),
    );
    _trips[index] = updated;
    return updated;
  }

  @override
  Future<OperationTripModel> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) async {
    final index = _trips.indexWhere((trip) => trip.id == tripId);
    if (index == -1) throw ArgumentError('Trip not found');
    final existing = _trips[index];
    final seats = existing.seats.map((seat) {
      if (seat.id != seatId) return seat;
      final clearCustomer =
          state == TripSeatState.available || state == TripSeatState.blocked;
      return seat.copyWith(
        state: state,
        clearPassengerName: clearCustomer,
        clearPickup: clearCustomer,
        notes: state == TripSeatState.blocked
            ? 'حظره فريق خدمة العملاء'
            : seat.notes,
      );
    }).toList();
    final updatedSeat = seats.firstWhere((seat) => seat.id == seatId);
    final event = TripEvent(
      title: 'Seat Updated',
      time: 'الآن',
      description:
          'تم تغيير المقعد ${updatedSeat.label} إلى ${updatedSeat.state.label}',
      done: true,
    );
    final updated = OperationTripModel.fromEntity(
      existing.copyWith(
        seats: seats,
        passengers: _passengersFromSeats(seats),
        events: [event, ...existing.events],
      ),
    );
    _trips[index] = updated;
    return updated;
  }
}

const _payments = [
  TripPayment(
    passengerName: 'سارة أحمد',
    amount: '١٢٠ ج.م',
    method: 'بطاقة',
    status: 'مدفوع',
  ),
  TripPayment(
    passengerName: 'خالد محمود',
    amount: '١٢٠ ج.م',
    method: 'تحويل',
    status: 'قيد المراجعة',
  ),
];

const _events = [
  TripEvent(
    title: 'Created',
    time: '٧:١٠ صباحاً',
    description: 'تم إنشاء الرحلة من جدول التشغيل.',
    done: true,
  ),
  TripEvent(
    title: 'Assigned Driver',
    time: '٧:٢٠ صباحاً',
    description: 'تم إسناد السائق والمركبة.',
    done: true,
  ),
  TripEvent(
    title: 'Started',
    time: '٨:٣٠ صباحاً',
    description: 'انطلاق الرحلة من نقطة البداية.',
    done: true,
  ),
  TripEvent(
    title: 'Arrived',
    time: '٩:٤٠ صباحاً',
    description: 'وصول متوقع أو فعلي حسب الحالة.',
    done: false,
  ),
  TripEvent(
    title: 'Completed',
    time: '٩:٥٠ صباحاً',
    description: 'إغلاق الرحلة بعد الوصول.',
    done: false,
  ),
];

List<TripSeat> _seatMap({
  required int total,
  required Set<int> reserved,
  required Set<int> confirmed,
  required Set<int> blocked,
}) {
  return List<TripSeat>.generate(total, (index) {
    final number = index + 1;
    final state = confirmed.contains(number)
        ? TripSeatState.confirmed
        : reserved.contains(number)
        ? TripSeatState.reserved
        : blocked.contains(number)
        ? TripSeatState.blocked
        : TripSeatState.available;
    final hasPassenger =
        state == TripSeatState.confirmed || state == TripSeatState.reserved;
    return TripSeat(
      id: 'seat-$number',
      label: '$number',
      row: index ~/ 4,
      column: index % 4,
      state: state,
      passengerName: hasPassenger ? _customerName(number) : null,
      pickup: hasPassenger ? _pickupName(number) : null,
      notes: state == TripSeatState.blocked ? 'محظور للصيانة أو المشرف' : '',
    );
  });
}

List<TripPassenger> _passengersFromSeats(List<TripSeat> seats) {
  return seats
      .where(
        (seat) =>
            seat.state == TripSeatState.confirmed ||
            seat.state == TripSeatState.reserved,
      )
      .map(
        (seat) => TripPassenger(
          name: seat.passengerName ?? 'عميل غير محدد',
          seat: seat.label,
          pickup: seat.pickup ?? 'غير محدد',
          status: seat.state == TripSeatState.confirmed ? 'مؤكد' : 'محجوز',
        ),
      )
      .toList();
}

String _customerName(int seatNumber) {
  const names = [
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
  return names[(seatNumber - 1) % names.length];
}

String _pickupName(int seatNumber) {
  const pickups = [
    'محطة بنها الرئيسية',
    'موقف شبرا',
    'بوابة الشيخ زايد',
    'الدائري',
  ];
  return pickups[(seatNumber - 1) % pickups.length];
}

final _trip221Seats = _seatMap(
  total: 12,
  reserved: {2, 7, 11},
  confirmed: {1, 3, 4, 6, 8},
  blocked: {12},
);

final _trip224Seats = _seatMap(
  total: 14,
  reserved: {5, 9},
  confirmed: {1, 2, 3, 4, 6, 7, 8, 10},
  blocked: {13, 14},
);

final _trip225Seats = _seatMap(
  total: 8,
  reserved: {3, 4, 6},
  confirmed: {1, 2, 5},
  blocked: {},
);

final _trip226Seats = _seatMap(
  total: 14,
  reserved: {1, 4, 9, 12},
  confirmed: {2, 3, 5, 6, 7, 8, 10, 11},
  blocked: {14},
);

final _trip220Seats = _seatMap(
  total: 8,
  reserved: {},
  confirmed: {1, 2, 3, 4, 5, 6, 7},
  blocked: {},
);

final _trip219Seats = _seatMap(
  total: 11,
  reserved: {},
  confirmed: {},
  blocked: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11},
);

final _seedTrips = [
  OperationTripModel(
    id: 'trip-221',
    route: 'بنها - مدينة نصر',
    driver: 'كريم حسن',
    vehicle: 'س د هـ ٧٨٩',
    date: '٨ يونيو ٢٠٢٦',
    departure: '٨:٣٠ صباحاً',
    arrival: '٩:٣٥ صباحاً',
    status: OperationTripStatus.inProgress,
    seats: _trip221Seats,
    passengers: _passengersFromSeats(_trip221Seats),
    payments: _payments,
    events: _events,
    notes: ['متابعة الوصول عند الدائري', 'راكب واحد لم يؤكد الحضور'],
  ),
  OperationTripModel(
    id: 'trip-224',
    route: 'بنها - القرية الذكية',
    driver: 'محمد أحمد',
    vehicle: 'أ ب ج ٤٥٦',
    date: '٨ يونيو ٢٠٢٦',
    departure: '٧:٤٥ صباحاً',
    arrival: '٩:٠٠ صباحاً',
    status: OperationTripStatus.ready,
    seats: _trip224Seats,
    passengers: _passengersFromSeats(_trip224Seats),
    payments: _payments,
    events: _events,
    notes: ['المركبة جاهزة', 'السائق أكد الحضور'],
  ),
  OperationTripModel(
    id: 'trip-225',
    route: 'بنها - المهندسين',
    driver: 'بانتظار الإسناد',
    vehicle: 'بانتظار المركبة',
    date: '٨ يونيو ٢٠٢٦',
    departure: '١٠:٠٠ صباحاً',
    arrival: '١١:١٠ صباحاً',
    status: OperationTripStatus.waiting,
    seats: _trip225Seats,
    passengers: _passengersFromSeats(_trip225Seats),
    payments: _payments,
    events: _events,
    notes: ['تحتاج سائق قبل الانطلاق'],
  ),
  OperationTripModel(
    id: 'trip-226',
    route: 'بنها - القرية الذكية',
    driver: 'هاني صلاح',
    vehicle: 'م ن و ٣٣١',
    date: '٨ يونيو ٢٠٢٦',
    departure: '١٢:٠٠ ظهراً',
    arrival: '١:١٥ ظهراً',
    status: OperationTripStatus.scheduled,
    seats: _trip226Seats,
    passengers: _passengersFromSeats(_trip226Seats),
    payments: _payments,
    events: _events,
    notes: ['رحلة منتصف اليوم'],
  ),
  OperationTripModel(
    id: 'trip-220',
    route: 'بنها - مدينة نصر',
    driver: 'كريم حسن',
    vehicle: 'س د هـ ٧٨٩',
    date: '٧ يونيو ٢٠٢٦',
    departure: '٦:٣٠ صباحاً',
    arrival: '٧:٣٥ صباحاً',
    status: OperationTripStatus.completed,
    seats: _trip220Seats,
    passengers: _passengersFromSeats(_trip220Seats),
    payments: _payments,
    events: _events,
    notes: ['مكتملة بدون ملاحظات حرجة'],
  ),
  OperationTripModel(
    id: 'trip-219',
    route: 'بنها - المهندسين',
    driver: 'مصطفى علي',
    vehicle: 'ق ل م ٨٨٠',
    date: '٧ يونيو ٢٠٢٦',
    departure: '٥:٣٠ صباحاً',
    arrival: '٦:٤٥ صباحاً',
    status: OperationTripStatus.cancelled,
    seats: _trip219Seats,
    passengers: [],
    payments: [],
    events: _events,
    notes: ['تم إلغاء الرحلة بسبب خروج المركبة من الخدمة'],
  ),
];
