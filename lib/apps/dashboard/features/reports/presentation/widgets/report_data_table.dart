import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/report_entities.dart';
import '../cubit/reports_state.dart';

class ReportDataTable extends StatelessWidget {
  final ReportsLoaded state;
  const ReportDataTable({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = state.reportData.rows;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('سجل البيانات المفصلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('عدد السجلات: ${rows.length}', style: const TextStyle(fontSize: 11, color: AppStatusColors.onNeutralContainer)),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (rows.isEmpty)
            const EmptyState(
              title: 'لا توجد سجلات بيانات لتحديد الفلتر الحالي',
              subtitle: 'يرجى تجربة تعديل فترة التصفية الزمنية أو خيارات الفلترة.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTable(context),
            ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = state.reportData.rows;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.2), // ~50/255
      ),
      child: switch (state.activeReportType) {
        ReportType.trips => DataTable(
            columns: const [
              DataColumn(label: Text('كود الرحلة')),
              DataColumn(label: Text('المسار')),
              DataColumn(label: Text('السائق')),
              DataColumn(label: Text('المركبة')),
              DataColumn(label: Text('الركاب')),
              DataColumn(label: Text('نسبة الإشغال')),
              DataColumn(label: Text('الإيرادات')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('الحالة')),
            ],
            rows: rows.cast<TripReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.tripId, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(r.routeCode)),
                DataCell(Text(r.driverName)),
                DataCell(Text(r.vehiclePlate)),
                DataCell(Text('${r.passengerCount} راكب')),
                DataCell(Text('${(r.occupancyRate * 100).toStringAsFixed(0)}%')),
                DataCell(Text('${r.revenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text(r.date.toString().substring(0, 10))),
                DataCell(Text(r.status, style: TextStyle(color: r.status == 'مكتملة' ? AppStatusColors.onSuccessContainer : AppStatusColors.onErrorContainer, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ReportType.bookings => DataTable(
            columns: const [
              DataColumn(label: Text('رقم الحجز')),
              DataColumn(label: Text('العميل')),
              DataColumn(label: Text('كود الرحلة')),
              DataColumn(label: Text('المبلغ')),
              DataColumn(label: Text('طريقة الدفع')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('التاريخ')),
            ],
            rows: rows.cast<BookingReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.bookingId, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(r.clientName)),
                DataCell(Text(r.tripId)),
                DataCell(Text('${r.amount.toStringAsFixed(0)} ج.م')),
                DataCell(Text(r.paymentMethod)),
                DataCell(Text(r.status, style: TextStyle(color: r.status == 'مؤكدة' ? AppStatusColors.onSuccessContainer : AppStatusColors.onErrorContainer, fontWeight: FontWeight.bold))),
                DataCell(Text(r.date.toString().substring(0, 16))),
              ]);
            }).toList(),
          ),
        ReportType.revenue => DataTable(
            columns: const [
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('إجمالي الإيرادات')),
              DataColumn(label: Text('إيرادات الرحلات')),
              DataColumn(label: Text('إيرادات الاشتراكات')),
              DataColumn(label: Text('عدد المرتجعات')),
              DataColumn(label: Text('صافي الإيرادات')),
            ],
            rows: rows.cast<RevenueReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.date.toString().substring(0, 10), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${r.totalRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text('${r.bookingsRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text('${r.subscriptionsRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text('${r.refundsCount} عمليات')),
                DataCell(Text('${r.netRevenue.toStringAsFixed(0)} ج.م', style: const TextStyle(color: AppStatusColors.onSuccessContainer, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ReportType.drivers => DataTable(
            columns: const [
              DataColumn(label: Text('رقم السائق')),
              DataColumn(label: Text('الاسم')),
              DataColumn(label: Text('الرحلات المكتملة')),
              DataColumn(label: Text('ساعات العمل')),
              DataColumn(label: Text('التقييم')),
              DataColumn(label: Text('إيرادات محققة')),
              DataColumn(label: Text('الحالة')),
            ],
            rows: rows.cast<DriverReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.driverId, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(r.name)),
                DataCell(Text('${r.completedTrips} رحلة')),
                DataCell(Text('${r.totalWorkingHours.toStringAsFixed(0)} ساعة')),
                DataCell(Text('${r.rating.toStringAsFixed(1)} ★', style: const TextStyle(color: AppStatusColors.onWarningContainer, fontWeight: FontWeight.bold))),
                DataCell(Text('${r.totalRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text(r.status, style: TextStyle(color: r.status == 'نشط' ? AppStatusColors.onSuccessContainer : AppStatusColors.onWarningContainer, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ReportType.vehicles => DataTable(
            columns: const [
              DataColumn(label: Text('كود المركبة')),
              DataColumn(label: Text('رقم اللوحة')),
              DataColumn(label: Text('الموديل')),
              DataColumn(label: Text('الرحلات المنجزة')),
              DataColumn(label: Text('معدل الوقود')),
              DataColumn(label: Text('حالة الصيانة')),
              DataColumn(label: Text('حالة التشغيل')),
            ],
            rows: rows.cast<VehicleReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.vehicleId, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(r.plateNumber)),
                DataCell(Text(r.model)),
                DataCell(Text('${r.completedTrips} رحلة')),
                DataCell(Text('${r.fuelConsumption.toStringAsFixed(1)} لتر/100كم')),
                DataCell(Text(r.maintenanceStatus, style: TextStyle(color: r.maintenanceStatus == 'جاهزة' ? AppStatusColors.onSuccessContainer : AppStatusColors.onErrorContainer, fontWeight: FontWeight.bold))),
                DataCell(Text(r.status)),
              ]);
            }).toList(),
          ),
        ReportType.subscriptions => DataTable(
            columns: const [
              DataColumn(label: Text('اسم الباقة')),
              DataColumn(label: Text('المشتركين النشطين')),
              DataColumn(label: Text('الاشتراكات المنتهية')),
              DataColumn(label: Text('إجمالي المبيعات')),
              DataColumn(label: Text('عمليات التجديد')),
            ],
            rows: rows.cast<SubscriptionReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.packageName, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${r.activeUsers} مستخدم')),
                DataCell(Text('${r.expiredUsers} مستخدم')),
                DataCell(Text('${r.totalRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text('${r.renewalsCount} تجديد')),
              ]);
            }).toList(),
          ),
        ReportType.complaints => DataTable(
            columns: const [
              DataColumn(label: Text('التصنيف')),
              DataColumn(label: Text('إجمالي الشكاوى')),
              DataColumn(label: Text('تم حلها')),
              DataColumn(label: Text('متوسط وقت الحل')),
              DataColumn(label: Text('معلقة')),
            ],
            rows: rows.cast<ComplaintReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.category, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${r.totalComplaints} شكوى')),
                DataCell(Text('${r.resolvedComplaints} شكوى')),
                DataCell(Text('${r.avgResolutionTime.toStringAsFixed(1)} ساعة')),
                DataCell(Text('${r.pendingComplaints} شكوى معلقة', style: TextStyle(color: r.pendingComplaints > 0 ? AppStatusColors.onErrorContainer : AppStatusColors.onNeutralContainer))),
              ]);
            }).toList(),
          ),
      },
    );
  }
}
