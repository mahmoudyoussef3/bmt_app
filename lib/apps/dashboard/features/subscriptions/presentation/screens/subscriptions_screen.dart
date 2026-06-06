import '../../../../core/widgets/dashboard_operations_screen.dart';

class SubscriptionsScreen extends DashboardOperationsScreen {
  const SubscriptionsScreen({super.key})
    : super(
        title: 'الاشتراكات',
        subtitle: 'متابعة الباقات والتجديدات للركاب.',
        actions: const ['تجديد اشتراك', 'تعديل باقة', 'إيقاف مؤقت'],
        columns: const ['العميل', 'الباقة', 'الرصيد', 'الحالة'],
        rows: const [
          ['سارة أحمد', 'شهري', '١٨ رحلة', 'نشط'],
          ['ياسمين علي', 'شهري', '٣ رحلات', 'ينتهي قريباً'],
        ],
      );
}
