import '../../../../core/widgets/dashboard_operations_screen.dart';

class UsersScreen extends DashboardOperationsScreen {
  const UsersScreen({super.key})
    : super(
        title: 'المستخدمين',
        subtitle: 'بيانات العملاء وسجل الحجوزات والتذاكر.',
        actions: const ['إضافة مستخدم', 'إنشاء حجز', 'فتح التذاكر'],
        columns: const ['الاسم', 'الهاتف', 'الحجوزات', 'الحالة'],
        rows: const [
          ['سارة أحمد', '٠١٠١٢٣٤٥٦٧٨', '٤٨', 'نشط'],
          ['خالد محمود', '٠١٢٣٤٥٦٧٨٩٠', '٣٢', 'يحتاج متابعة'],
        ],
      );
}
