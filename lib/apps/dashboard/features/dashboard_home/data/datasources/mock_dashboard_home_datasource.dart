import '../models/dashboard_home_model.dart';
import '../../domain/entities/dashboard_home_data.dart';

abstract class DashboardHomeDatasource {
  Future<DashboardHomeModel> fetchHomeData();
}

class MockDashboardHomeDatasource implements DashboardHomeDatasource {
  @override
  Future<DashboardHomeModel> fetchHomeData() async {
    return const DashboardHomeModel(
      metrics: [
        DashboardMetric(
          label: 'الحجوزات اليوم',
          value: '١٥٦',
          note: '٢٣ حجز يحتاج متابعة',
        ),
        DashboardMetric(
          label: 'الرحلات الجارية',
          value: '١٢',
          note: '٣ رحلات تحتاج تدخل',
        ),
        DashboardMetric(
          label: 'السائقين المتاحين',
          value: '٢٦',
          note: 'جاهزون للإسناد',
        ),
        DashboardMetric(
          label: 'الشكاوى المفتوحة',
          value: '٨',
          note: '٢ أولوية عالية',
        ),
      ],
      recentBookings: [
        DashboardQueueItem(
          title: 'حجز ٩٨٧٢',
          subtitle: 'سارة أحمد - بنها إلى القرية الذكية',
          status: 'مؤكد',
        ),
        DashboardQueueItem(
          title: 'حجز ٩٨٧٣',
          subtitle: 'خالد محمود - بنها إلى مدينة نصر',
          status: 'في الانتظار',
        ),
        DashboardQueueItem(
          title: 'حجز ٩٨٧٤',
          subtitle: 'رنا يوسف - طلب تعديل موعد',
          status: 'جديد',
        ),
      ],
      tripsNeedingAction: [
        DashboardQueueItem(
          title: 'رحلة ٢٢٤',
          subtitle: 'تحتاج إسناد مركبة قبل الانطلاق',
          status: 'تدخل مطلوب',
        ),
        DashboardQueueItem(
          title: 'رحلة ٢٢١',
          subtitle: 'السائق تأخر عن نقطة التجمع',
          status: 'متأخرة',
        ),
      ],
      delayedDrivers: [
        DashboardQueueItem(
          title: 'محمد أحمد',
          subtitle: 'آخر تحديث منذ ١٢ دقيقة',
          status: 'في رحلة',
        ),
        DashboardQueueItem(
          title: 'كريم حسن',
          subtitle: 'ينتظر تأكيد الوصول',
          status: 'متاح',
        ),
      ],
      openTickets: [
        DashboardQueueItem(
          title: 'شكوى ١٠٠١',
          subtitle: 'مشكلة دفع - خالد محمود',
          status: 'عالية',
        ),
        DashboardQueueItem(
          title: 'شكوى ١٠٠٢',
          subtitle: 'تغيير موعد - رنا يوسف',
          status: 'متوسطة',
        ),
      ],
    );
  }
}
