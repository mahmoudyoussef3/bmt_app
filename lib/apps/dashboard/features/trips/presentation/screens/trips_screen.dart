import '../../../../core/widgets/dashboard_operations_screen.dart';

class TripsScreen extends DashboardOperationsScreen {
  const TripsScreen({super.key})
    : super(
        title: 'الرحلات',
        subtitle: 'إنشاء الرحلات وتعديلها وإسناد السائق والمركبة.',
        actions: const ['إنشاء رحلة', 'إسناد سائق', 'إسناد مركبة'],
        columns: const ['رقم الرحلة', 'المسار', 'السائق', 'الحالة'],
        rows: const [
          ['٢٢٤', 'بنها - القرية الذكية', 'محمد أحمد', 'قادمة'],
          ['٢٢١', 'بنها - مدينة نصر', 'كريم حسن', 'جارية'],
          ['٢٢٣', 'بنها - المهندسين', 'مصطفى علي', 'تحتاج تدخل'],
        ],
      );
}
