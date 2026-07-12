import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/report_entities.dart';

class ReportExportService {
  Future<Uint8List> generateExportBytes(
    ReportData data,
    ReportType type,
    String format,
  ) async {
    final List<List<dynamic>> rowsAsList = _mapDataToList(data.rows, type);

    switch (format.toLowerCase()) {
      case 'csv':
        return _generateCsv(rowsAsList);
      case 'excel':
        return _generateExcel(rowsAsList, type.label);
      case 'pdf':
        return await _generatePdf(rowsAsList, type.label);
      default:
        throw Exception('Unsupported format: $format');
    }
  }

  Uint8List _generateCsv(List<List<dynamic>> rows) {
    // Add UTF-8 BOM for Arabic support in Excel
    final List<int> utf8BOM = [0xEF, 0xBB, 0xBF];
    final String csvData = const CsvEncoder().convert(rows);
    return Uint8List.fromList([...utf8BOM, ...csvData.codeUnits]);
  }

  Uint8List _generateExcel(List<List<dynamic>> rows, String sheetName) {
    var excel = Excel.createExcel();
    var sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      for (int j = 0; j < row.length; j++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i),
        );
        cell.value = TextCellValue(row[j].toString());
      }
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> _generatePdf(List<List<dynamic>> rows, String title) async {
    final doc = pw.Document();

    final arabicFont = await PdfGoogleFonts.cairoRegular();

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title, style: const pw.TextStyle(fontSize: 24)),
          ),
          pw.SizedBox(height: 20),
          if (rows.isNotEmpty)
            pw.TableHelper.fromTextArray(
              context: context,
              data: rows,
              cellAlignment: pw.Alignment.centerRight,
              cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
              headerStyle: pw.TextStyle(
                font: arabicFont,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
        ],
      ),
    );

    return await doc.save();
  }

  List<List<dynamic>> _mapDataToList(List<dynamic> rows, ReportType type) {
    if (rows.isEmpty) return [];

    List<List<dynamic>> result = [];

    switch (type) {
      case ReportType.trips:
        result.add([
          'كود الرحلة',
          'المسار',
          'السائق',
          'المركبة',
          'الركاب',
          'نسبة الإشغال',
          'الإيرادات',
          'التاريخ',
          'الحالة',
        ]);
        for (final row in rows.cast<TripReportRow>()) {
          result.add([
            row.tripId,
            row.routeCode,
            row.driverName,
            row.vehiclePlate,
            row.passengerCount,
            row.occupancyRate,
            row.revenue,
            row.date.toString().substring(0, 10),
            row.status,
          ]);
        }
        break;
      case ReportType.bookings:
        result.add([
          'رقم الحجز',
          'العميل',
          'كود الرحلة',
          'المبلغ',
          'طريقة الدفع',
          'الحالة',
          'التاريخ',
        ]);
        for (final row in rows.cast<BookingReportRow>()) {
          result.add([
            row.bookingId,
            row.clientName,
            row.tripId,
            row.amount,
            row.paymentMethod,
            row.status,
            row.date.toString().substring(0, 16),
          ]);
        }
        break;
      case ReportType.revenue:
        result.add([
          'التاريخ',
          'إجمالي الإيرادات',
          'إيرادات الرحلات',
          'إيرادات الاشتراكات',
          'عدد المرتجعات',
          'صافي الإيرادات',
        ]);
        for (final row in rows.cast<RevenueReportRow>()) {
          result.add([
            row.date.toString().substring(0, 10),
            row.totalRevenue,
            row.bookingsRevenue,
            row.subscriptionsRevenue,
            row.refundsCount,
            row.netRevenue,
          ]);
        }
        break;
      case ReportType.drivers:
        result.add([
          'رقم السائق',
          'الاسم',
          'الرحلات المكتملة',
          'ساعات العمل',
          'التقييم',
          'إيرادات محققة',
          'الحالة',
        ]);
        for (final row in rows.cast<DriverReportRow>()) {
          result.add([
            row.driverId,
            row.name,
            row.completedTrips,
            row.totalWorkingHours,
            row.rating,
            row.totalRevenue,
            row.status,
          ]);
        }
        break;
      case ReportType.vehicles:
        result.add([
          'كود المركبة',
          'رقم اللوحة',
          'الموديل',
          'الرحلات المنجزة',
          'معدل الوقود',
          'حالة الصيانة',
          'حالة التشغيل',
        ]);
        for (final row in rows.cast<VehicleReportRow>()) {
          result.add([
            row.vehicleId,
            row.plateNumber,
            row.model,
            row.completedTrips,
            row.fuelConsumption,
            row.maintenanceStatus,
            row.status,
          ]);
        }
        break;
      case ReportType.subscriptions:
        result.add([
          'اسم الباقة',
          'المشتركين النشطين',
          'الاشتراكات المنتهية',
          'إجمالي المبيعات',
          'عمليات التجديد',
        ]);
        for (final row in rows.cast<SubscriptionReportRow>()) {
          result.add([
            row.packageName,
            row.activeUsers,
            row.expiredUsers,
            row.totalRevenue,
            row.renewalsCount,
          ]);
        }
        break;
      case ReportType.complaints:
        result.add([
          'التصنيف',
          'إجمالي الشكاوى',
          'تم حلها',
          'متوسط وقت الحل',
          'معلقة',
        ]);
        for (final row in rows.cast<ComplaintReportRow>()) {
          result.add([
            row.category,
            row.totalComplaints,
            row.resolvedComplaints,
            row.avgResolutionTime,
            row.pendingComplaints,
          ]);
        }
        break;
    }

    return result;
  }
}
