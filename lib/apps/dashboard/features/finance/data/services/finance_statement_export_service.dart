import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/finance_analytics.dart';

/// Serialises a [FinanceStatement] to CSV / Excel / PDF.
///
/// All three formats carry the *same* sections in the same order — income
/// statement, then payment-method breakdown, then the daily table, then the
/// transaction ledger — so whichever file the owner opens, it says exactly what
/// the screen said.
class FinanceStatementExportService {
  Future<Uint8List> generateExportBytes(
    FinanceStatement statement,
    String format,
  ) async {
    switch (format.toLowerCase()) {
      case 'csv':
        return _generateCsv(statement);
      case 'excel':
        return _generateExcel(statement);
      case 'pdf':
        return _generatePdf(statement);
      default:
        throw ArgumentError('صيغة تصدير غير مدعومة: $format');
    }
  }

  Uint8List _generateCsv(FinanceStatement statement) {
    final rows = <List<dynamic>>[];
    for (final section in _sections(statement)) {
      rows
        ..add([section.title])
        ..add(section.header)
        ..addAll(section.rows)
        ..add(const []);
    }
    // `addBom` + real UTF-8 encoding: without the BOM Excel renders the Arabic
    // headers as mojibake, and encoding via `String.codeUnits` would mangle
    // every non-Latin character on the way out.
    final csv = const CsvEncoder(addBom: true).convert(rows);
    return Uint8List.fromList(utf8.encode(csv));
  }

  Uint8List _generateExcel(FinanceStatement statement) {
    final excel = Excel.createExcel();
    final sheetName = 'التقرير المالي';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    var rowIndex = 0;
    void write(List<dynamic> values) {
      for (var column = 0; column < values.length; column++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: rowIndex,
                  ),
                )
                .value =
            TextCellValue(values[column].toString());
      }
      rowIndex++;
    }

    for (final section in _sections(statement)) {
      write([section.title]);
      write(section.header);
      section.rows.forEach(write);
      write(const []);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('تعذر توليد ملف Excel للتقرير المالي.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> _generatePdf(FinanceStatement statement) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'التقرير المالي — ${statement.periodLabel}',
                  style: pw.TextStyle(font: boldFont, fontSize: 20),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'تاريخ الإصدار: ${_formatDateTime(statement.generatedAt)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          for (final section in _sections(statement)) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              section.title,
              style: pw.TextStyle(font: boldFont, fontSize: 13),
            ),
            pw.SizedBox(height: 6),
            if (section.rows.isEmpty)
              pw.Text('لا توجد بيانات', style: const pw.TextStyle(fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                context: context,
                data: [section.header, ...section.rows],
                cellAlignment: pw.Alignment.centerRight,
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  List<_ExportSection> _sections(FinanceStatement statement) {
    final gross = statement.summary
        .firstWhere(
          (line) => line.isSubtotal,
          orElse: () => const FinanceStatementLine('', 0),
        )
        .amount;

    return [
      _ExportSection(
        title: 'قائمة الدخل — ${statement.periodLabel}',
        header: const ['البند', 'المبلغ (ج.م)'],
        rows: [
          for (final line in statement.summary)
            [line.label, _money(line.amount)],
        ],
      ),
      _ExportSection(
        title: 'التوزيع حسب طريقة الدفع',
        header: const ['طريقة الدفع', 'عدد العمليات', 'المبلغ (ج.م)', 'النسبة'],
        rows: [
          for (final row in statement.byMethod)
            [
              row.label,
              row.count,
              _money(row.amount),
              _percent(row.shareOf(gross)),
            ],
        ],
      ),
      _ExportSection(
        title: 'الحركة اليومية',
        header: const [
          'التاريخ',
          'عدد المعاملات',
          'صافي المحصّل (ج.م)',
          'مرتجعات (ج.م)',
          'قيد التحصيل (ج.م)',
        ],
        rows: [
          for (final point in statement.daily)
            [
              _formatDate(point.date),
              point.transactions,
              _money(point.net),
              _money(point.refunded),
              _money(point.pending),
            ],
        ],
      ),
      _ExportSection(
        title: 'سجل الحركات المالية',
        header: const [
          'التاريخ',
          'النوع',
          'العميل',
          'المرجع',
          'طريقة الدفع',
          'الحالة',
          'المبلغ (ج.م)',
        ],
        rows: [
          for (final entry in statement.entries)
            [
              _formatDateTime(entry.date),
              entry.type.label,
              entry.party,
              entry.reference,
              entry.method?.label ?? '—',
              entry.status.label,
              _money(entry.amount),
            ],
        ],
      ),
    ];
  }

  static String _money(double value) => value.toStringAsFixed(2);

  static String _percent(double share) =>
      '${(share * 100).toStringAsFixed(1)}%';

  static String _formatDate(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _formatDateTime(DateTime date) =>
      '${_formatDate(date)} ${_two(date.hour)}:${_two(date.minute)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _ExportSection {
  final String title;
  final List<String> header;
  final List<List<dynamic>> rows;

  const _ExportSection({
    required this.title,
    required this.header,
    required this.rows,
  });
}
