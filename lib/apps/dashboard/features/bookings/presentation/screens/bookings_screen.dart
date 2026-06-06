import '../../../../core/widgets/dashboard_operations_screen.dart';

class BookingsScreen extends DashboardOperationsScreen {
  const BookingsScreen({super.key})
    : super(
        title: 'الحجوزات',
        subtitle: 'متابعة الحجوزات وتغيير الحالة وربط الحجز برحلة.',
        actions: const ['حجز جديد', 'تعديل الحجز', 'إلغاء الحجز'],
        columns: const ['رقم الحجز', 'العميل', 'الرحلة', 'الحالة'],
        rows: const [
          ['٩٨٧٢', 'سارة أحمد', '٢٢٤', 'مؤكد'],
          ['٩٨٧٣', 'خالد محمود', '٢٢١', 'في الانتظار'],
          ['٩٨٧٤', 'رنا يوسف', '٢٢٣', 'جديد'],
        ],
      );
}
