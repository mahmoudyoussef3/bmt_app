import '../../../../core/widgets/dashboard_operations_screen.dart';

class ReportsScreen extends DashboardOperationsScreen {
  const ReportsScreen({super.key})
    : super(
        title: 'التقارير',
        subtitle: 'تقارير بسيطة للتشغيل مع إجراءات التصدير.',
        actions: const ['تصدير الحجوزات', 'تصدير الرحلات', 'تصدير المدفوعات'],
        columns: const ['التقرير', 'الفترة', 'آخر تحديث', 'الحالة'],
        rows: const [
          ['الحجوزات', 'اليوم', 'منذ ٥ دقائق', 'جاهز'],
          ['المدفوعات', 'هذا الأسبوع', 'منذ ساعة', 'جاهز'],
        ],
      );
}
