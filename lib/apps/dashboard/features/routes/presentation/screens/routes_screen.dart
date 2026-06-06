import '../../../../core/widgets/dashboard_operations_screen.dart';

class RoutesScreen extends DashboardOperationsScreen {
  const RoutesScreen({super.key})
    : super(
        title: 'المسارات',
        subtitle: 'إدارة خطوط التشغيل ونقاط التجمع.',
        actions: const ['إضافة مسار', 'تعديل نقاط', 'تعطيل مسار'],
        columns: const ['المسار', 'البداية', 'النهاية', 'الحالة'],
        rows: const [
          ['القرية الذكية', 'بنها', 'القرية الذكية', 'نشط'],
          ['مدينة نصر', 'بنها', 'مدينة نصر', 'نشط'],
        ],
      );
}
