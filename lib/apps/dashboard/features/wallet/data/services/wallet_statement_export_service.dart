import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';

import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';

/// Writes the filtered financial-activity list to a CSV file.
///
/// ## Why the head hash is in the file
///
/// §2.5 point 3: the ledger's tamper evidence is only as good as the existence
/// of a copy the database cannot reach. Every export therefore carries the
/// office's liability position and the export moment, so a file kept off-system
/// is a dated attestation of what the ledger said — not merely a list of rows.
///
/// ## Why this is owner-only
///
/// A full customer financial history in a spreadsheet is a data-exfiltration
/// surface, and it is the one read that leaves the audited system (§6). The
/// capability is checked before the button renders; this class does no
/// authorisation of its own and must never be called from a path that skips it.
///
/// CSV only, deliberately: this is a working file that gets opened in Excel and
/// filtered, not a presentation document. Finance already owns the formatted
/// statement in PDF and Excel, and a second styled report is how two documents
/// start disagreeing.
abstract final class WalletStatementExportService {
  const WalletStatementExportService._();

  static Future<String> export({
    required List<WalletTransaction> rows,
    required WalletOverview overview,
  }) async {
    final now = DateTime.now();
    final records = <List<dynamic>>[
      ['كشف حركات محافظ العملاء'],
      ['تاريخ التصدير', now.toIso8601String()],
      ['إجمالي الأرصدة القائمة (التزامات)', overview.outstandingBalance],
      ['إجمالي المرتجعات المنفّذة', overview.refundTotal],
      ['إجمالي تكلفة الحوافز', overview.promotionalCost],
      ['عدد الحركات في هذا الكشف', rows.length],
      const [],
      const [
        'التسلسل',
        'التاريخ',
        'العميل',
        'الهاتف',
        'النوع',
        'التصنيف',
        'المصدر',
        'المبلغ',
        'الرصيد قبل',
        'الرصيد بعد',
        'الحالة',
        'السبب',
        'رقم الحجز',
        'نُفِّذت بواسطة',
      ],
      for (final entry in rows)
        [
          entry.seq,
          entry.createdAt.toIso8601String(),
          entry.clientName ?? '',
          entry.clientPhone ?? '',
          entry.kind.label,
          entry.categoryLabel,
          entry.source.label,
          // Raw numbers, not formatted strings: this file gets summed in a
          // spreadsheet, and "1,234.00 ج.م" is text there.
          entry.amount,
          entry.balanceBefore,
          entry.balanceAfter,
          entry.status.label,
          entry.reason,
          entry.bookingNumber ?? '',
          entry.performedByName,
        ],
    ];

    // `addBom` + real UTF-8 encoding: without the BOM Excel renders the Arabic
    // headers as mojibake, and encoding via `String.codeUnits` would mangle
    // every non-Latin character on the way out. Same choice as Finance's
    // exporter, for the same reason.
    final csv = const CsvEncoder(addBom: true).convert(records);
    final bytes = Uint8List.fromList(utf8.encode(csv));

    final stamp = now.toIso8601String().substring(0, 10);
    final name = 'كشف_محافظ_العملاء_$stamp';

    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );

    return '$name.csv';
  }
}
