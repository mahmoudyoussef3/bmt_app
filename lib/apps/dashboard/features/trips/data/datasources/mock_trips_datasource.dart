import '../../domain/entities/operation_trip.dart';
import '../models/operation_trip_model.dart';

abstract class TripsDatasource {
  Future<List<OperationTripModel>> fetchTrips();
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status,
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
}

const _passengers = [
  TripPassenger(
    name: 'سارة أحمد',
    seat: '٦',
    pickup: 'محطة بنها الرئيسية',
    status: 'حاضر',
  ),
  TripPassenger(
    name: 'خالد محمود',
    seat: '٧',
    pickup: 'موقف شبرا',
    status: 'في الانتظار',
  ),
  TripPassenger(
    name: 'رنا يوسف',
    seat: '٨',
    pickup: 'بوابة الشيخ زايد',
    status: 'حاضر',
  ),
];

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

const _seedTrips = [
  OperationTripModel(
    id: 'trip-221',
    route: 'بنها - مدينة نصر',
    driver: 'كريم حسن',
    vehicle: 'س د هـ ٧٨٩',
    passengersCount: 8,
    departure: '٨:٣٠ صباحاً',
    arrival: '٩:٣٥ صباحاً',
    status: OperationTripStatus.inProgress,
    passengers: _passengers,
    payments: _payments,
    events: _events,
    notes: ['متابعة الوصول عند الدائري', 'راكب واحد لم يؤكد الحضور'],
  ),
  OperationTripModel(
    id: 'trip-224',
    route: 'بنها - القرية الذكية',
    driver: 'محمد أحمد',
    vehicle: 'أ ب ج ٤٥٦',
    passengersCount: 10,
    departure: '٧:٤٥ صباحاً',
    arrival: '٩:٠٠ صباحاً',
    status: OperationTripStatus.ready,
    passengers: _passengers,
    payments: _payments,
    events: _events,
    notes: ['المركبة جاهزة', 'السائق أكد الحضور'],
  ),
  OperationTripModel(
    id: 'trip-225',
    route: 'بنها - المهندسين',
    driver: 'بانتظار الإسناد',
    vehicle: 'بانتظار المركبة',
    passengersCount: 6,
    departure: '١٠:٠٠ صباحاً',
    arrival: '١١:١٠ صباحاً',
    status: OperationTripStatus.waiting,
    passengers: _passengers,
    payments: _payments,
    events: _events,
    notes: ['تحتاج سائق قبل الانطلاق'],
  ),
  OperationTripModel(
    id: 'trip-226',
    route: 'بنها - القرية الذكية',
    driver: 'هاني صلاح',
    vehicle: 'م ن و ٣٣١',
    passengersCount: 12,
    departure: '١٢:٠٠ ظهراً',
    arrival: '١:١٥ ظهراً',
    status: OperationTripStatus.scheduled,
    passengers: _passengers,
    payments: _payments,
    events: _events,
    notes: ['رحلة منتصف اليوم'],
  ),
  OperationTripModel(
    id: 'trip-220',
    route: 'بنها - مدينة نصر',
    driver: 'كريم حسن',
    vehicle: 'س د هـ ٧٨٩',
    passengersCount: 7,
    departure: '٦:٣٠ صباحاً',
    arrival: '٧:٣٥ صباحاً',
    status: OperationTripStatus.completed,
    passengers: _passengers,
    payments: _payments,
    events: _events,
    notes: ['مكتملة بدون ملاحظات حرجة'],
  ),
  OperationTripModel(
    id: 'trip-219',
    route: 'بنها - المهندسين',
    driver: 'مصطفى علي',
    vehicle: 'ق ل م ٨٨٠',
    passengersCount: 0,
    departure: '٥:٣٠ صباحاً',
    arrival: '٦:٤٥ صباحاً',
    status: OperationTripStatus.cancelled,
    passengers: [],
    payments: [],
    events: _events,
    notes: ['تم إلغاء الرحلة بسبب خروج المركبة من الخدمة'],
  ),
];
