import '../../domain/entities/operation_booking.dart';
import '../models/operation_booking_model.dart';

abstract class BookingsDatasource {
  Future<List<OperationBookingModel>> fetchBookings();
  Future<OperationBookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  );
  Future<List<OperationBookingModel>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  );
  Future<List<OperationBookingModel>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  );
}

class MockBookingsDatasource implements BookingsDatasource {
  final List<OperationBookingModel> _bookings =
      List<OperationBookingModel>.from(_seedBookings);

  @override
  Future<List<OperationBookingModel>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  ) async {
    final updated = <OperationBookingModel>[];
    for (final id in bookingIds) {
      final index = _bookings.indexWhere((booking) => booking.id == id);
      if (index == -1) continue;
      final booking = _bookings[index].copyWith(
        assignedTrip: tripId,
        history: ['تم الإسناد إلى رحلة $tripId', ..._bookings[index].history],
      );
      final model = OperationBookingModel.fromEntity(booking);
      _bookings[index] = model;
      updated.add(model);
    }
    return updated;
  }

  @override
  Future<List<OperationBookingModel>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  ) async {
    final updated = <OperationBookingModel>[];
    for (final id in bookingIds) {
      updated.add(await updateBookingStatus(id, status));
    }
    return updated;
  }

  @override
  Future<List<OperationBookingModel>> fetchBookings() async {
    return List<OperationBookingModel>.unmodifiable(_bookings);
  }

  @override
  Future<OperationBookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) throw ArgumentError('Booking not found');
    final booking = _bookings[index].copyWith(
      status: status,
      history: [
        'تم تحديث الحالة إلى ${status.label}',
        ..._bookings[index].history,
      ],
    );
    final model = OperationBookingModel.fromEntity(booking);
    _bookings[index] = model;
    return model;
  }
}

OperationBookingModel _booking({
  required String id,
  required String name,
  required String phone,
  required String route,
  required String time,
  required String date,
  required String seat,
  required BookingPaymentMethod method,
  required BookingStatus status,
  required String trip,
}) {
  return OperationBookingModel(
    id: id,
    passengerName: name,
    phone: phone,
    route: route,
    tripTime: time,
    date: date,
    seat: seat,
    paymentMethod: method,
    status: status,
    assignedTrip: trip,
    customerProfile: BookingCustomerProfile(
      name: name,
      phone: phone,
      email: '$id@bmt.local',
      tripsCount: '٢٨ رحلة',
      accountStatus: 'نشط',
    ),
    tripDetails: BookingTripDetails(
      route: route,
      date: date,
      time: time,
      vehicle: 'أ ب ج ٤٥٦',
      driver: 'محمد أحمد',
    ),
    paymentDetails: BookingPaymentDetails(
      amount: '١٢٠ ج.م',
      method: method,
      status: method == BookingPaymentMethod.bankTransfer
          ? 'قيد المراجعة'
          : 'مدفوع',
      reference: 'PAY-$id',
    ),
    attachments: ['إيصال دفع وهمي', 'صورة طلب تعديل'],
    notes: ['طلب من خدمة العملاء', 'يرجى تأكيد المقعد قبل الانطلاق'],
    history: ['تم إنشاء الطلب', 'تمت مراجعته من قائمة الحجوزات'],
  );
}

final _seedBookings = [
  _booking(
    id: 'B-1001',
    name: 'سارة أحمد',
    phone: '٠١٠١٢٣٤٥٦٧٨',
    route: 'بنها - القرية الذكية',
    time: '٨:٣٠ صباحاً',
    date: 'اليوم',
    seat: '٦',
    method: BookingPaymentMethod.card,
    status: BookingStatus.newRequest,
    trip: 'غير مسند',
  ),
  _booking(
    id: 'B-1002',
    name: 'خالد محمود',
    phone: '٠١٢٣٤٥٦٧٨٩٠',
    route: 'بنها - مدينة نصر',
    time: '٩:٠٠ صباحاً',
    date: 'اليوم',
    seat: '٧',
    method: BookingPaymentMethod.bankTransfer,
    status: BookingStatus.underReview,
    trip: 'TR-221',
  ),
  _booking(
    id: 'B-1003',
    name: 'رنا يوسف',
    phone: '٠١١١٢٢٢٣٣٣٤',
    route: 'بنها - المهندسين',
    time: '١٠:٠٠ صباحاً',
    date: 'غداً',
    seat: '٣',
    method: BookingPaymentMethod.wallet,
    status: BookingStatus.confirmed,
    trip: 'TR-225',
  ),
  _booking(
    id: 'B-1004',
    name: 'ياسمين علي',
    phone: '٠١٥٥٦٦٦٧٧٧٨',
    route: 'بنها - القرية الذكية',
    time: '١٢:٠٠ ظهراً',
    date: 'اليوم',
    seat: '١٠',
    method: BookingPaymentMethod.cash,
    status: BookingStatus.newRequest,
    trip: 'غير مسند',
  ),
  _booking(
    id: 'B-1005',
    name: 'محمود علي',
    phone: '٠١٠٩٩٨٨٧٧٦٦',
    route: 'بنها - التجمع',
    time: '٢:٠٠ ظهراً',
    date: 'الأسبوع ده',
    seat: '٥',
    method: BookingPaymentMethod.card,
    status: BookingStatus.cancelled,
    trip: 'TR-219',
  ),
];
