import '../../domain/entities/booking_payment_verification.dart';
import '../models/booking_payment_verification_model.dart';
import 'booking_payment_verification_datasource.dart';

/// Test double for the verification queue. Not registered in DI (the app uses
/// the Supabase datasource); retained only for repository tests.
class MockBookingPaymentVerificationDatasource
    implements BookingPaymentVerificationDatasource {
  final List<BookingPaymentVerificationModel> _items =
      List<BookingPaymentVerificationModel>.from(_seedVerifications);

  @override
  Future<List<BookingPaymentVerificationModel>> fetchQueue() async {
    return List<BookingPaymentVerificationModel>.unmodifiable(_items);
  }

  @override
  Future<BookingPaymentVerificationModel> approve(
    String verificationId,
    String note,
  ) async {
    return _update(
      verificationId,
      status: BookingVerificationStatus.approved,
      seatState: VerificationSeatState.permanentlyConfirmed,
      title: 'تم قبول الدفع',
      note: note,
      description: 'تم تأكيد المقعد نهائياً بعد مطابقة الإيصال.',
    );
  }

  @override
  Future<BookingPaymentVerificationModel> reject(
    String verificationId,
    String note,
  ) async {
    return _update(
      verificationId,
      status: BookingVerificationStatus.rejected,
      seatState: VerificationSeatState.released,
      title: 'تم رفض الدفع',
      note: note,
      description: 'تم تحرير المقعد لأن الدفع غير مطابق.',
    );
  }

  @override
  Future<BookingPaymentVerificationModel> requestReview(
    String verificationId,
    String note,
  ) async {
    return _update(
      verificationId,
      status: BookingVerificationStatus.reviewRequested,
      seatState: VerificationSeatState.temporaryReserved,
      title: 'طلب مراجعة إضافية',
      note: note,
      description: 'المقعد ما زال مؤقتاً لحين استكمال بيانات الإيصال.',
    );
  }

  @override
  Future<BookingPaymentVerificationModel> addNote(
    String verificationId,
    String note,
  ) async {
    return _update(
      verificationId,
      status: null,
      seatState: null,
      title: 'إضافة ملاحظة',
      note: note,
      description: 'تمت إضافة ملاحظة من خدمة العملاء.',
    );
  }

  BookingPaymentVerificationModel _update(
    String verificationId, {
    required BookingVerificationStatus? status,
    required VerificationSeatState? seatState,
    required String title,
    required String note,
    required String description,
  }) {
    final index = _items.indexWhere((item) => item.id == verificationId);
    if (index == -1) throw ArgumentError('Verification not found');
    final item = _items[index];
    final normalizedNote = note.trim();
    final updated = BookingPaymentVerificationModel.fromEntity(
      item.copyWith(
        status: status,
        seatState: seatState,
        notes: normalizedNote.isEmpty
            ? item.notes
            : [normalizedNote, ...item.notes],
        history: [
          VerificationHistoryItem(
            title: title,
            time: 'الآن',
            description: description,
          ),
          ...item.history,
        ],
      ),
    );
    _items[index] = updated;
    return updated;
  }
}

const _seedVerifications = [
  BookingPaymentVerificationModel(
    id: 'ver-1001',
    bookingId: 'B-1002',
    customer: VerificationCustomer(
      name: 'خالد محمود',
      phone: '٠١٢٣٤٥٦٧٨٩٠',
      email: 'khaled@bmt.local',
      profileStatus: 'عميل نشط - ١٨ رحلة',
    ),
    trip: VerificationTrip(
      tripId: 'TR-221',
      route: 'بنها - مدينة نصر',
      date: '٨ يونيو ٢٠٢٦',
      time: '٩:٠٠ صباحاً',
      vehicle: 'س د هـ ٧٨٩',
      driver: 'كريم حسن',
    ),
    selectedSeat: '٧',
    seatState: VerificationSeatState.temporaryReserved,
    amount: '١٢٠ ج.م',
    method: VerificationPaymentMethod.bankTransfer,
    referenceNumber: 'BNK-49201877',
    receiptTitle: 'إيصال تحويل بنكي',
    receiptMeta: 'صورة واضحة من تطبيق البنك - تم الرفع بعد الحجز بدقيقتين',
    status: BookingVerificationStatus.pending,
    notes: ['العميل رفع الإيصال من تطبيق الموبايل.'],
    history: [
      VerificationHistoryItem(
        title: 'رفع الإيصال',
        time: '٩:٠٤ صباحاً',
        description: 'أصبح الحجز بانتظار تحقق خدمة العملاء.',
      ),
      VerificationHistoryItem(
        title: 'إنشاء الحجز',
        time: '٩:٠٠ صباحاً',
        description: 'تم حجز المقعد ٧ بشكل مؤقت.',
      ),
    ],
  ),
  BookingPaymentVerificationModel(
    id: 'ver-1002',
    bookingId: 'B-1006',
    customer: VerificationCustomer(
      name: 'منة خالد',
      phone: '٠١٠٩٩٨٨٧٧٦٦',
      email: 'menna@bmt.local',
      profileStatus: 'عميل جديد',
    ),
    trip: VerificationTrip(
      tripId: 'TR-224',
      route: 'بنها - القرية الذكية',
      date: '٨ يونيو ٢٠٢٦',
      time: '٧:٤٥ صباحاً',
      vehicle: 'أ ب ج ٤٥٦',
      driver: 'محمد أحمد',
    ),
    selectedSeat: '٩',
    seatState: VerificationSeatState.temporaryReserved,
    amount: '١٤٠ ج.م',
    method: VerificationPaymentMethod.wallet,
    referenceNumber: 'WLT-84221903',
    receiptTitle: 'لقطة شاشة محفظة',
    receiptMeta: 'آخر ٤ أرقام من العملية غير واضحة',
    status: BookingVerificationStatus.reviewRequested,
    notes: ['مطلوب إعادة رفع صورة أوضح.'],
    history: [
      VerificationHistoryItem(
        title: 'طلب مراجعة',
        time: '٨:١٢ صباحاً',
        description: 'تم طلب صورة أوضح قبل تثبيت المقعد.',
      ),
    ],
  ),
  BookingPaymentVerificationModel(
    id: 'ver-1003',
    bookingId: 'B-1007',
    customer: VerificationCustomer(
      name: 'رنا يوسف',
      phone: '٠١١١٢٢٢٣٣٣٤',
      email: 'rana@bmt.local',
      profileStatus: 'عميل نشط - ٣٤ رحلة',
    ),
    trip: VerificationTrip(
      tripId: 'TR-225',
      route: 'بنها - المهندسين',
      date: '٩ يونيو ٢٠٢٦',
      time: '١٠:٠٠ صباحاً',
      vehicle: 'ر ز ط ١٢٣',
      driver: 'هاني صلاح',
    ),
    selectedSeat: '٣',
    seatState: VerificationSeatState.permanentlyConfirmed,
    amount: '١٢٠ ج.م',
    method: VerificationPaymentMethod.card,
    referenceNumber: 'CRD-11028451',
    receiptTitle: 'إيصال دفع بطاقة',
    receiptMeta: 'مطابق لقيمة الرحلة والمقعد المختار',
    status: BookingVerificationStatus.approved,
    notes: ['تم تثبيت المقعد بعد المطابقة.'],
    history: [
      VerificationHistoryItem(
        title: 'تم قبول الدفع',
        time: 'أمس ٧:٥٢ مساءً',
        description: 'المقعد ٣ مؤكد نهائياً.',
      ),
    ],
  ),
];
