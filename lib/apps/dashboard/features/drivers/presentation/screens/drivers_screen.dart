import '../../../../core/widgets/dashboard_operations_screen.dart';

class DriversScreen extends DashboardOperationsScreen {
  const DriversScreen({super.key})
    : super(
        title: 'السائقين',
        subtitle: 'حالة السائقين والرحلات الحالية والتقييم.',
        actions: const ['إضافة سائق', 'تعديل البيانات', 'عرض الرحلات'],
        columns: const ['السائق', 'الهاتف', 'الحالة', 'التقييم'],
        rows: const [
          ['محمد أحمد', '٠١٠١٢٣٤٥٦٧٨', 'متاح', '٤.٨'],
          ['كريم حسن', '٠١٢٣٤٥٦٧٨٩٠', 'في رحلة', '٤.٦'],
        ],
      );
}
