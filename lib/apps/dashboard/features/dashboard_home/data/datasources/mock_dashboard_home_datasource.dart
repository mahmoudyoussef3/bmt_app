import '../models/dashboard_home_model.dart';
import '../../domain/entities/dashboard_home_data.dart';

abstract class DashboardHomeDatasource {
  Future<DashboardHomeModel> fetchHomeData();
}

class MockDashboardHomeDatasource implements DashboardHomeDatasource {
  @override
  Future<DashboardHomeModel> fetchHomeData() async {
    return const DashboardHomeModel(
      actionItems: [
        OperationsActionItem(
          title: 'حجز بانتظار مراجعة الدفع',
          count: '١٢',
          description: 'إيصالات محولة تحتاج اعتماد أو رفض قبل تثبيت الكراسي',
          targetModule: '/payment-verification',
          priority: OperationsPriority.urgent,
        ),
        OperationsActionItem(
          title: 'شكاوى مفتوحة',
          count: '٤',
          description: 'بلاغات عملاء تحتاج متابعة من خدمة العملاء',
          targetModule: '/tickets',
          priority: OperationsPriority.high,
        ),
        OperationsActionItem(
          title: 'اشتراكات بانتظار الاعتماد',
          count: '٣',
          description: 'طلبات باقات شهرية على مسارات القاهرة الكبرى',
          targetModule: '/subscriptions',
          priority: OperationsPriority.high,
        ),
        OperationsActionItem(
          title: 'رحلة متأخرة',
          count: '٢',
          description: 'تأخير فعلي في الانطلاق أو الوصول لنقطة التجمع',
          targetModule: '/live-trips',
          priority: OperationsPriority.urgent,
        ),
        OperationsActionItem(
          title: 'رحلات لم يبدأ السائق فيها بعد',
          count: '٥',
          description: 'رحلات مكتملة البيانات والسائق لم يسجل بدء التنفيذ',
          targetModule: '/trips',
          priority: OperationsPriority.high,
        ),
        OperationsActionItem(
          title: 'مستند مركبة منتهي',
          count: '١',
          description: 'رخصة سير تحتاج تجديد قبل تشغيل المركبة مرة أخرى',
          targetModule: '/vehicles',
          priority: OperationsPriority.urgent,
        ),
        OperationsActionItem(
          title: 'رخصة سائق أوشكت على الانتهاء',
          count: '٢',
          description: 'متبقي أقل من ١٤ يوم على انتهاء الرخصة',
          targetModule: '/drivers',
          priority: OperationsPriority.normal,
        ),
      ],
      todayTrips: [
        TodayTripSummary(
          name: 'رحلة صباحية ١٠٥',
          route: 'بنها - شبرا - رمسيس - القرية الذكية',
          driver: 'أحمد عبد الرازق',
          vehicle: 'تويوتا كوستر ٣٣٤٥ ق ل',
          departureTime: '٧:١٥ ص',
          capacity: 28,
          bookedSeats: 26,
          status: 'لم تبدأ',
        ),
        TodayTripSummary(
          name: 'رحلة موظفين ٢١٨',
          route: 'المعادي - التجمع الخامس - العاصمة الإدارية',
          driver: 'مصطفى سمير',
          vehicle: 'مرسيدس سبرنتر ٧٢١٨ م ن',
          departureTime: '٨:٠٠ ص',
          capacity: 19,
          bookedSeats: 19,
          status: 'في الطريق',
        ),
        TodayTripSummary(
          name: 'رحلة جامعة ٣٣٢',
          route: 'مدينة نصر - مصر الجديدة - الجامعة البريطانية',
          driver: 'كريم فتحي',
          vehicle: 'هيونداي H1 ٩٠٢١ ص ج',
          departureTime: '٩:٣٠ ص',
          capacity: 12,
          bookedSeats: 8,
          status: 'وصلت أول نقطة',
        ),
        TodayTripSummary(
          name: 'رحلة عودة ٤٠٧',
          route: 'القرية الذكية - رمسيس - شبرا - بنها',
          driver: 'محمد سامي',
          vehicle: 'تويوتا هايس ١٥٥٢ ج ب',
          departureTime: '٥:٤٥ م',
          capacity: 14,
          bookedSeats: 11,
          status: 'متأخرة',
        ),
      ],
      paymentReviews: [
        PaymentReviewItem(
          customerName: 'سارة محمود',
          tripName: 'رحلة صباحية ١٠٥',
          method: 'إنستاباي',
          amount: '٣٢٠ ج.م',
          receiptTitle: 'إيصال تحويل إنستاباي',
          receiptMeta: 'مرجع: IPA-44291 - ٧:٤٨ ص',
        ),
        PaymentReviewItem(
          customerName: 'خالد عادل',
          tripName: 'رحلة موظفين ٢١٨',
          method: 'فودافون كاش',
          amount: '٤٥٠ ج.م',
          receiptTitle: 'صورة محفظة إلكترونية',
          receiptMeta: 'رقم العملية: 739104 - ٨:١٢ ص',
        ),
      ],
      openComplaints: [
        ComplaintTicket(
          customerName: 'منى إبراهيم',
          type: 'تأخير رحلة',
          tripName: 'رحلة عودة ٤٠٧',
          lastUpdate: 'منذ ١٠ دقائق',
          owner: 'أ. ندى',
          status: 'جديدة',
        ),
        ComplaintTicket(
          customerName: 'عمرو حسين',
          type: 'مقعد غير مطابق',
          tripName: 'رحلة صباحية ١٠٥',
          lastUpdate: 'منذ ٣٢ دقيقة',
          owner: 'أ. أحمد',
          status: 'قيد المعالجة',
        ),
        ComplaintTicket(
          customerName: 'ريم طارق',
          type: 'سلوك قيادة',
          tripName: 'رحلة موظفين ٢١٨',
          lastUpdate: 'منذ ساعة',
          owner: 'مشرف التشغيل',
          status: 'مصعدة',
        ),
      ],
      subscriptions: [
        SubscriptionReviewItem(
          customerName: 'نهى جمال',
          packageName: 'باقة عمل شهرية',
          route: 'بنها - القرية الذكية',
          startDate: '١٠ يونيو ٢٠٢٦',
          endDate: '٩ يوليو ٢٠٢٦',
          remainingTrips: 22,
          status: 'بانتظار الاعتماد',
        ),
        SubscriptionReviewItem(
          customerName: 'أحمد هشام',
          packageName: 'باقة جامعة',
          route: 'مدينة نصر - الجامعة البريطانية',
          startDate: '١ يونيو ٢٠٢٦',
          endDate: '٣٠ يونيو ٢٠٢٦',
          remainingTrips: 14,
          status: 'نشط',
        ),
        SubscriptionReviewItem(
          customerName: 'داليا شوقي',
          packageName: 'باقة ١٢ رحلة',
          route: 'المعادي - التجمع الخامس',
          startDate: '٢٠ مايو ٢٠٢٦',
          endDate: '١٢ يونيو ٢٠٢٦',
          remainingTrips: 2,
          status: 'قارب على الانتهاء',
        ),
      ],
      alerts: [
        OperationsAlert(
          title: 'رحلة عودة ٤٠٧ متأخرة',
          details: 'تأخير ١٨ دقيقة عند الخروج من القرية الذكية',
          targetModule: '/live-trips',
          priority: OperationsPriority.urgent,
        ),
        OperationsAlert(
          title: 'مركبة تحتاج صيانة',
          details: 'تويوتا هايس ١٥٥٢ ج ب - صيانة دورية خلال ٢٤ ساعة',
          targetModule: '/vehicles',
          priority: OperationsPriority.high,
        ),
        OperationsAlert(
          title: 'مستند مركبة منتهي',
          details: 'كوستر ٣٣٤٥ ق ل - تأمين المركبة انتهى اليوم',
          targetModule: '/vehicles',
          priority: OperationsPriority.urgent,
        ),
        OperationsAlert(
          title: 'سائق لم يبدأ الرحلة',
          details: 'رحلة صباحية ١٠٥ لم يتم بدء تنفيذها رغم اقتراب موعدها',
          targetModule: '/trips',
          priority: OperationsPriority.high,
        ),
        OperationsAlert(
          title: 'رحلة ممتلئة بالكامل',
          details: 'رحلة موظفين ٢١٨ لا يوجد بها مقاعد متاحة',
          targetModule: '/trips',
          priority: OperationsPriority.normal,
        ),
      ],
    );
  }
}
