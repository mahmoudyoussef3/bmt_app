import '../../domain/entities/finance_payment.dart';
import '../models/finance_payment_model.dart';

abstract class PaymentsDatasource {
  Future<List<FinancePayment>> fetchPayments();

  Future<FinancePayment> updateStatus(
    String paymentId,
    PaymentReviewStatus status,
  );

  Future<FinancePayment> addNote(String paymentId, String note);

  Future<List<Map<String, dynamic>>> fetchAvailableTrips();

  Future<void> reassignBooking(String bookingId, String newTripId);
}

class MockPaymentsDatasource implements PaymentsDatasource {
  final List<FinancePayment> _payments = [
    const FinancePaymentModel(
      id: 'pay-1001',
      userName: 'أحمد سامي',
      amount: '1,250 ج.م',
      method: FinancePaymentMethod.bankTransfer,
      paidAt: 'اليوم 09:12 ص',
      status: PaymentReviewStatus.pendingReview,
      user: 'أحمد سامي - 01011223344',
      trip: 'رحلة التجمع - وسط البلد 08:30 ص',
      packageName: 'باقة شهرية - 22 رحلة',
      referenceNumber: 'BNK-49201877',
      receiptLabel: 'إيصال تحويل بنكي',
      receiptMeta: 'صورة مرفوعة من تطبيق البنك',
      notes: ['تم استلام صورة إيصال واضحة.'],
      history: [
        PaymentHistoryItem(
          title: 'تم إنشاء طلب المراجعة',
          time: '09:13 ص',
          description: 'النظام أضاف الدفعة لقائمة المراجعة المالية.',
        ),
      ],
    ),
    const FinancePaymentModel(
      id: 'pay-1002',
      userName: 'منة خالد',
      amount: '480 ج.م',
      method: FinancePaymentMethod.wallet,
      paidAt: 'اليوم 10:05 ص',
      status: PaymentReviewStatus.needsReview,
      user: 'منة خالد - 01099887766',
      trip: 'رحلة أكتوبر - المعادي 05:00 م',
      packageName: 'اشتراك أسبوعي',
      referenceNumber: 'WLT-84221903',
      receiptLabel: 'لقطة شاشة محفظة',
      receiptMeta: 'الرقم المرجعي غير واضح بالكامل',
      notes: ['يحتاج تأكيد آخر 4 أرقام من العملية.'],
      history: [
        PaymentHistoryItem(
          title: 'طلب مراجعة إضافية',
          time: '10:08 ص',
          description: 'المراجع المالي طلب تأكيد رقم العملية.',
        ),
      ],
    ),
    const FinancePaymentModel(
      id: 'pay-1003',
      userName: 'كريم عادل',
      amount: '2,100 ج.م',
      method: FinancePaymentMethod.card,
      paidAt: 'أمس 07:44 م',
      status: PaymentReviewStatus.accepted,
      user: 'كريم عادل - 01122334455',
      trip: 'رحلة الرحاب - الزمالك 07:15 ص',
      packageName: 'باقة شركات',
      referenceNumber: 'CRD-11028451',
      receiptLabel: 'إيصال دفع بطاقة',
      receiptMeta: 'مطابق لقيمة الاشتراك',
      notes: ['تمت المطابقة مع رقم العملية.'],
      history: [
        PaymentHistoryItem(
          title: 'تم قبول الدفعة',
          time: 'أمس 07:52 م',
          description: 'تمت مراجعة الإيصال وتأكيد الاشتراك.',
        ),
      ],
    ),
    const FinancePaymentModel(
      id: 'pay-1004',
      userName: 'سارة ياسر',
      amount: '350 ج.م',
      method: FinancePaymentMethod.cash,
      paidAt: 'أمس 02:20 م',
      status: PaymentReviewStatus.rejected,
      user: 'سارة ياسر - 01255667788',
      trip: 'رحلة مدينة نصر - القرية الذكية 06:45 ص',
      packageName: 'رحلة مفردة',
      referenceNumber: 'CSH-000184',
      receiptLabel: 'إيصال نقدي',
      receiptMeta: 'الإيصال غير مطابق للرحلة',
      notes: ['تم رفض الدفعة لعدم تطابق بيانات الإيصال.'],
      history: [
        PaymentHistoryItem(
          title: 'تم رفض الدفعة',
          time: 'أمس 02:37 م',
          description: 'قيمة الإيصال تخص رحلة مختلفة.',
        ),
      ],
    ),
  ];

  @override
  Future<List<FinancePayment>> fetchPayments() async {
    return List.unmodifiable(_payments);
  }

  @override
  Future<FinancePayment> updateStatus(
    String paymentId,
    PaymentReviewStatus status,
  ) async {
    final index = _payments.indexWhere((payment) => payment.id == paymentId);
    if (index == -1) {
      throw StateError('Payment not found');
    }

    final payment = _payments[index];
    final updated = FinancePaymentModel.fromEntity(
      payment.copyWith(
        status: status,
        history: [
          PaymentHistoryItem(
            title: 'تحديث الحالة إلى ${status.label}',
            time: 'الآن',
            description: 'تم تنفيذ الإجراء من شاشة مراجعة المدفوعات.',
          ),
          ...payment.history,
        ],
      ),
    );
    _payments[index] = updated;
    return updated;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAvailableTrips() async => const [];

  @override
  Future<void> reassignBooking(String bookingId, String newTripId) async {}

  @override
  Future<FinancePayment> addNote(String paymentId, String note) async {
    final index = _payments.indexWhere((payment) => payment.id == paymentId);
    if (index == -1) {
      throw StateError('Payment not found');
    }

    final payment = _payments[index];
    final updated = FinancePaymentModel.fromEntity(
      payment.copyWith(
        notes: [note, ...payment.notes],
        history: [
          const PaymentHistoryItem(
            title: 'إضافة ملاحظة',
            time: 'الآن',
            description: 'تم تسجيل ملاحظة مالية على الدفعة.',
          ),
          ...payment.history,
        ],
      ),
    );
    _payments[index] = updated;
    return updated;
  }
}
