import 'dart:math';
import '../../domain/entities/finance_entities.dart';
import 'finance_datasource.dart';

class MockFinanceDatasource implements FinanceDatasource {
  final List<PaymentRecord> _payments = [];
  final List<ReceiptReview> _receipts = [];
  final List<RefundRequest> _refunds = [];
  final List<SubscriptionRecord> _subscriptions = [];

  MockFinanceDatasource() {
    _generateData();
  }

  void _generateData() {
    final random = Random(42); // Seeded for deterministic generation

    final names = [
      'أحمد محمود', 'محمد علي', 'عمر فاروق', 'يوسف حسين', 'محمود حسن',
      'خالد وليد', 'طارق سعيد', 'عبد الرحمن محمد', 'إبراهيم علي', 'مصطفى كامل',
      'أحمد حسن', 'محمد عبد الله', 'عمرو دياب', 'كريم عبد العزيز', 'هاني سلامة',
      'أحمد حلمي', 'ياسر جلال', 'شريف منير', 'سليمان عيد', 'ماجد الكدواني',
      'رانيا يوسف', 'مي عز الدين', 'منى زكي', 'هند صبري', 'ياسمين عبد العزيز',
      'كريم محمود', 'أحمد زاهر', 'نيللي كريم', 'أسر ياسين', 'عمرو يوسف'
    ];

    final trips = [
      'CAI-ALX-01', 'ALX-SHM-02', 'CAI-GIZ-03', 'SHM-DAB-04', 'ASW-LUX-05',
      'CAI-SUZ-06', 'ALX-CAI-07', 'HRG-CAI-08', 'CAI-SHM-09', 'DAB-CAI-10'
    ];

    final reasons = [
      'إلغاء الرحلة من قبل العميل',
      'تأخر الحافلة عن الموعد المحدد',
      'تعديل خط سير الرحلة',
      'دفع مكرر بالخطأ',
      'عدم تمكن العميل من الركوب بسبب ظروف طارئة',
      'عدم مطابقة الخدمة للتوقعات'
    ];

    // 1. Generate 500 payment records
    for (int i = 1; i <= 500; i++) {
      final method = FinancePaymentMethod.values[random.nextInt(FinancePaymentMethod.values.length)];
      
      // Status distribution: 82% success, 10% pending, 4% cancelled, 4% refunded
      final randStatus = random.nextDouble();
      final PaymentStatus status;
      if (randStatus < 0.82) {
        status = PaymentStatus.success;
      } else if (randStatus < 0.92) {
        status = PaymentStatus.pending;
      } else if (randStatus < 0.96) {
        status = PaymentStatus.cancelled;
      } else {
        status = PaymentStatus.refunded;
      }

      final client = names[random.nextInt(names.length)];
      final trip = trips[random.nextInt(trips.length)];
      final amount = (50 + random.nextInt(30) * 20).toDouble(); // 50 to 650 EGP
      final daysAgo = random.nextInt(35);
      final date = DateTime.now().subtract(
        Duration(days: daysAgo, hours: random.nextInt(24), minutes: random.nextInt(60)),
      );

      _payments.add(PaymentRecord(
        id: 'TXN-${1000 + i}',
        clientName: client,
        tripCode: trip,
        amount: amount,
        paymentMethod: method,
        status: status,
        date: date,
      ));
    }

    // 2. Generate 200 receipts in the review queue
    for (int i = 1; i <= 200; i++) {
      final client = names[random.nextInt(names.length)];
      final trip = trips[random.nextInt(trips.length)];
      final amount = (120 + random.nextInt(20) * 25).toDouble(); // 120 to 620 EGP
      final daysAgo = random.nextInt(20);
      final date = DateTime.now().subtract(Duration(days: daysAgo, hours: random.nextInt(24)));

      // Ensure first 35 are pending, others are accepted/rejected/reupload requested
      final ReceiptReviewStatus status;
      if (i <= 35) {
        status = ReceiptReviewStatus.pending;
      } else if (i <= 140) {
        status = ReceiptReviewStatus.accepted;
      } else if (i <= 175) {
        status = ReceiptReviewStatus.rejected;
      } else {
        status = ReceiptReviewStatus.reuploadRequested;
      }

      // If accepted, associate with a valid successful payment, else request txn
      final String txnId;
      if (status == ReceiptReviewStatus.accepted) {
        // Link to one of the success payments generated above (between TXN-1001 and TXN-1400)
        final txnIndex = random.nextInt(400);
        txnId = _payments[txnIndex].id;
      } else {
        txnId = 'TXN-REQ-${5000 + i}';
      }

      final history = <String>[
        'تم رفع الإيصال من قبل العميل في ${date.toString().substring(0, 16)}',
      ];
      if (status == ReceiptReviewStatus.accepted) {
        history.add('تم قبول الإيصال وتأكيد العملية من قبل خدمة العملاء في ${date.add(const Duration(hours: 2)).toString().substring(0, 16)}');
      } else if (status == ReceiptReviewStatus.rejected) {
        history.add('تم رفض الإيصال بسبب عدم وضوح البيانات في ${date.add(const Duration(hours: 1)).toString().substring(0, 16)}');
      } else if (status == ReceiptReviewStatus.reuploadRequested) {
        history.add('تم طلب إعادة رفع الإيصال بسبب خطأ في رقم التحويل في ${date.add(const Duration(hours: 3)).toString().substring(0, 16)}');
      }

      _receipts.add(ReceiptReview(
        id: 'REC-${2000 + i}',
        transactionId: txnId,
        clientName: client,
        tripCode: trip,
        amount: amount,
        date: date,
        receiptUrl: 'assets/receipts/receipt_${(i % 5) + 1}.png',
        status: status,
        notes: status == ReceiptReviewStatus.rejected
            ? 'صورة الإيصال غير واضحة وغير مقروءة'
            : (status == ReceiptReviewStatus.reuploadRequested
                ? 'يرجى تصوير الإيصال بالكامل مع إظهار رقم العملية'
                : null),
        history: history,
      ));
    }

    // 3. Generate 50 refund requests
    for (int i = 1; i <= 50; i++) {
      // Pick a transaction from the generated payments list
      final txnIndex = random.nextInt(_payments.length);
      final originalTxn = _payments[txnIndex];

      final RefundStatus status;
      if (i <= 15) {
        status = RefundStatus.pending;
      } else if (i <= 40) {
        status = RefundStatus.approved;
      } else {
        status = RefundStatus.rejected;
      }

      final date = originalTxn.date.add(Duration(days: random.nextInt(3) + 1));

      final history = <String>[
        'تم تقديم طلب استرداد المبلغ من قبل العميل في ${date.toString().substring(0, 16)}',
      ];
      if (status == RefundStatus.approved) {
        history.add('تمت الموافقة على طلب المرتجع من قبل الإدارة المالية في ${date.add(const Duration(hours: 4)).toString().substring(0, 16)}');
      } else if (status == RefundStatus.rejected) {
        history.add('تم رفض طلب المرتجع: تجاوز العميل المهلة المسموح بها للإلغاء في ${date.add(const Duration(hours: 3)).toString().substring(0, 16)}');
      }

      _refunds.add(RefundRequest(
        id: 'REF-${3000 + i}',
        transactionId: originalTxn.id,
        clientName: originalTxn.clientName,
        amount: originalTxn.amount,
        date: date,
        status: status,
        reason: reasons[random.nextInt(reasons.length)],
        history: history,
      ));

      // Synchronize initial approved refunds with the payment statuses
      if (status == RefundStatus.approved) {
        final idx = _payments.indexWhere((p) => p.id == originalTxn.id);
        if (idx != -1) {
          _payments[idx] = _payments[idx].copyWith(status: PaymentStatus.refunded);
        }
      }
    }

    // 4. Generate 80 subscription records
    final packages = ['الباقة الأسبوعية', 'الباقة الشهرية', 'باقة 10 رحلات', 'باقة 30 رحلة', 'الباقة المميزة للطلاب'];
    final packagePrices = [180.0, 550.0, 280.0, 750.0, 380.0];

    for (int i = 1; i <= 80; i++) {
      final client = names[random.nextInt(names.length)];
      final pkgIdx = random.nextInt(packages.length);
      final pkg = packages[pkgIdx];
      final price = packagePrices[pkgIdx];

      final daysAgo = random.nextInt(25);
      final startDate = DateTime.now().subtract(Duration(days: daysAgo));
      final endDate = startDate.add(const Duration(days: 30));

      final SubscriptionStatus status;
      if (i <= 60) {
        status = SubscriptionStatus.active;
      } else if (i <= 72) {
        status = SubscriptionStatus.expired;
      } else {
        status = SubscriptionStatus.cancelled;
      }

      _subscriptions.add(SubscriptionRecord(
        id: 'SUB-${4000 + i}',
        clientName: client,
        packageName: pkg,
        amount: price,
        startDate: startDate,
        endDate: endDate,
        status: status,
        remainingRides: status == SubscriptionStatus.active ? random.nextInt(12) + 1 : 0,
      ));
    }
  }

  @override
  Future<List<PaymentRecord>> getPayments() async => List.unmodifiable(_payments);

  @override
  Future<List<ReceiptReview>> getReceiptReviews() async => List.unmodifiable(_receipts);

  @override
  Future<List<RefundRequest>> getRefundRequests() async => List.unmodifiable(_refunds);

  @override
  Future<List<SubscriptionRecord>> getSubscriptions() async => List.unmodifiable(_subscriptions);

  @override
  Future<RevenueMetrics> getRevenueMetrics() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = now.subtract(const Duration(days: 30));

    double today = 0.0;
    double weekly = 0.0;
    double monthly = 0.0;
    double totalBookings = 0.0;

    for (final p in _payments) {
      if (p.status == PaymentStatus.success) {
        totalBookings += p.amount;
        if (p.date.isAfter(todayStart)) {
          today += p.amount;
        }
        if (p.date.isAfter(weekStart)) {
          weekly += p.amount;
        }
        if (p.date.isAfter(monthStart)) {
          monthly += p.amount;
        }
      }
    }

    // Include active subscription revenues as part of total/monthly
    for (final s in _subscriptions) {
      if (s.status == SubscriptionStatus.active) {
        totalBookings += s.amount;
        if (s.startDate.isAfter(todayStart)) {
          today += s.amount;
        }
        if (s.startDate.isAfter(weekStart)) {
          weekly += s.amount;
        }
        if (s.startDate.isAfter(monthStart)) {
          monthly += s.amount;
        }
      }
    }

    final activeSubs = _subscriptions.where((s) => s.status == SubscriptionStatus.active).length;

    return RevenueMetrics(
      todayRevenue: today,
      weeklyRevenue: weekly,
      monthlyRevenue: monthly,
      activeSubscriptions: activeSubs,
      totalBookingsRevenue: totalBookings,
    );
  }

  // Update Methods
  @override
  Future<void> reviewReceipt(String id, ReceiptReviewStatus action, {String? notes}) async {
    final index = _receipts.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final original = _receipts[index];
    final dateStr = DateTime.now().toString().substring(0, 16);
    
    final updatedHistory = List<String>.from(original.history)
      ..add('تم تغيير الحالة إلى [${action.label}] في $dateStr من قبل المسؤول.');

    _receipts[index] = original.copyWith(
      status: action,
      notes: notes ?? original.notes,
      history: updatedHistory,
    );

    // If accepted, set corresponding transaction status to successful
    if (action == ReceiptReviewStatus.accepted) {
      final pIndex = _payments.indexWhere((p) => p.id == original.transactionId);
      if (pIndex != -1) {
        _payments[pIndex] = _payments[pIndex].copyWith(status: PaymentStatus.success);
      } else {
        // If not found, create a new success payment record
        _payments.insert(0, PaymentRecord(
          id: original.transactionId,
          clientName: original.clientName,
          tripCode: original.tripCode,
          amount: original.amount,
          paymentMethod: FinancePaymentMethod.instapay, // Default to Instapay
          status: PaymentStatus.success,
          date: DateTime.now(),
        ));
      }
    } else if (action == ReceiptReviewStatus.rejected) {
      // If rejected, set transaction status to cancelled
      final pIndex = _payments.indexWhere((p) => p.id == original.transactionId);
      if (pIndex != -1) {
        _payments[pIndex] = _payments[pIndex].copyWith(status: PaymentStatus.cancelled);
      }
    }
  }

  @override
  Future<void> processRefund(String id, RefundStatus action) async {
    final index = _refunds.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final original = _refunds[index];
    final dateStr = DateTime.now().toString().substring(0, 16);

    final updatedHistory = List<String>.from(original.history)
      ..add('تم تحديث حالة طلب المرتجع إلى [${action.label}] في $dateStr.');

    _refunds[index] = original.copyWith(
      status: action,
      history: updatedHistory,
    );

    // If approved, update payment status to refunded
    if (action == RefundStatus.approved) {
      final pIndex = _payments.indexWhere((p) => p.id == original.transactionId);
      if (pIndex != -1) {
        _payments[pIndex] = _payments[pIndex].copyWith(status: PaymentStatus.refunded);
      }
    }
  }

  @override
  Future<void> cancelSubscription(String id) async {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final original = _subscriptions[index];
    _subscriptions[index] = original.copyWith(
      status: SubscriptionStatus.cancelled,
    );
  }
}
