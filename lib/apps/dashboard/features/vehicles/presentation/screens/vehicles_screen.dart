import '../../../../core/widgets/dashboard_operations_screen.dart';

class VehiclesScreen extends DashboardOperationsScreen {
  const VehiclesScreen({super.key})
    : super(
        title: 'المركبات',
        subtitle: 'جاهزية المركبات والسعة والسائق الحالي.',
        actions: const ['إضافة مركبة', 'تعديل الحالة', 'إسناد سائق'],
        columns: const ['اللوحة', 'النوع', 'السعة', 'الحالة'],
        rows: const [
          ['أ ب ج ٤٥٦', 'ميني باص', '١٢', 'جاهزة'],
          ['س د هـ ٧٨٩', 'فان', '٨', 'في رحلة'],
        ],
      );
}
