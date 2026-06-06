import '../../../../core/widgets/dashboard_operations_screen.dart';

class PaymentsScreen extends DashboardOperationsScreen {
  const PaymentsScreen({super.key})
    : super(
        title: 'المدفوعات',
        subtitle: 'مراجعة المدفوعات والمبالغ المستردة وطرق الدفع.',
        actions: const ['قبول دفع', 'رفض دفع', 'رد مبلغ'],
        columns: const ['رقم الدفع', 'العميل', 'المبلغ', 'الحالة'],
        rows: const [
          ['١٠٠١', 'سارة أحمد', '١٢٠ ج.م', 'معلق'],
          ['١٠٠٢', 'خالد محمود', '٢٤٠ ج.م', 'مقبول'],
        ],
      );
}
