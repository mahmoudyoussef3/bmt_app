import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../../../../core/entitlements/licensed_export.dart';
import '../../domain/entities/operation_booking.dart';

/// Turns the operator's current view of the bookings queue into a CSV file.
///
/// Only CSV: the board offers one "تصدير" action, not the three-format
/// toolbar Reports/Finance expose for a full statement.
class BookingsCsvExportService {
  const BookingsCsvExportService();

  Future<Uint8List> generateCsvBytes(List<OperationBooking> bookings) async {
    await LicensedExport.consume('csv');

    final rows = <List<dynamic>>[
      [
        'رقم الحجز',
        'الراكب',
        'الهاتف',
        'الرحلة',
        'تاريخ الرحلة',
        'وقت الرحلة',
        'المقعد',
        'طريقة الدفع',
        'المبلغ',
        'حالة الحجز',
        'حالة الدفع',
        'تاريخ الإنشاء',
      ],
      for (final booking in bookings)
        [
          booking.bookingNumber,
          booking.passengerName,
          booking.phone,
          booking.route,
          booking.date,
          booking.tripTime,
          booking.seat,
          booking.paymentMethod.label,
          booking.paymentAmount,
          booking.status.label,
          booking.paymentStatus.label,
          booking.createdAt.toString().substring(0, 16),
        ],
    ];

    // UTF-8 BOM so Excel opens the Arabic columns correctly, matching the
    // report/finance/wallet exporters.
    final csv = const CsvEncoder(addBom: true).convert(rows);
    return Uint8List.fromList(utf8.encode(csv));
  }
}
