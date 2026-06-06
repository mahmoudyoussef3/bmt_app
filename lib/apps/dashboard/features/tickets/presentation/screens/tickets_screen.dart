import '../../../../core/widgets/dashboard_operations_screen.dart';

class TicketsScreen extends DashboardOperationsScreen {
  const TicketsScreen({super.key})
    : super(
        title: 'التذاكر',
        subtitle: 'كل التذاكر المفتوحة وقيد المعالجة والمغلقة.',
        actions: const ['تعيين مسؤول', 'رد على التذكرة', 'إغلاق'],
        columns: const ['رقم التذكرة', 'العميل', 'الأولوية', 'الحالة'],
        rows: const [
          ['١٠٠١', 'خالد محمود', 'عالية', 'مفتوحة'],
          ['١٠٠٢', 'رنا يوسف', 'متوسطة', 'قيد المعالجة'],
        ],
      );
}
