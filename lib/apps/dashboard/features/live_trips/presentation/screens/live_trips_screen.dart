import '../../../../core/widgets/dashboard_operations_screen.dart';

class LiveTripsScreen extends DashboardOperationsScreen {
  const LiveTripsScreen({super.key})
    : super(
        title: 'الرحلات المباشرة',
        subtitle: 'الرحلات الجارية الآن والتواصل السريع مع السائقين.',
        actions: const ['عرض مباشر', 'فتح التفاصيل', 'التواصل مع السائق'],
        columns: const ['رقم الرحلة', 'السائق', 'المركبة', 'الحالة'],
        rows: const [
          ['٢٢١', 'كريم حسن', 'أ ب ج ٤٥٦', 'في الطريق'],
          ['٢٢٦', 'هاني صلاح', 'س د هـ ٧٨٩', 'متأخرة'],
        ],
      );
}
