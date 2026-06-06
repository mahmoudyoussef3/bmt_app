import '../../../../core/widgets/dashboard_operations_screen.dart';

class PermissionsScreen extends DashboardOperationsScreen {
  const PermissionsScreen({super.key})
    : super(
        title: 'الصلاحيات',
        subtitle: 'إدارة أدوار الوصول للمسؤولين فقط.',
        actions: const ['تعديل صلاحية', 'إضافة مسؤول'],
        columns: const ['الدور', 'الوصول', 'الحالة'],
        rows: const [
          ['المسؤول', 'كل الأقسام', 'نشط'],
          ['خدمة العملاء', 'التشغيل وخدمة العملاء', 'نشط'],
        ],
      );
}
