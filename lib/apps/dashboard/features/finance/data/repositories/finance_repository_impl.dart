import 'package:file_saver/file_saver.dart';

import '../../domain/entities/finance_analytics.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/entities/finance_money_model.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_datasource.dart';
import '../services/finance_statement_export_service.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceDatasource _datasource;
  final FinanceStatementExportService _exportService;

  FinanceRepositoryImpl(
    this._datasource, {
    FinanceStatementExportService? exportService,
  }) : _exportService = exportService ?? FinanceStatementExportService();

  @override
  Future<List<PaymentRecord>> getPayments() => _datasource.getPayments();

  @override
  Future<List<RefundRequest>> getRefundRequests() =>
      _datasource.getRefundRequests();

  @override
  Future<List<SubscriptionRecord>> getSubscriptions() =>
      _datasource.getSubscriptions();

  @override
  Future<RevenueMetrics> getRevenueMetrics() => _datasource.getRevenueMetrics();

  @override
  Future<WalletFinancePosition> getWalletPosition() =>
      _datasource.getWalletPosition();

  @override
  Future<String> exportStatement(
    FinanceStatement statement,
    String format,
  ) async {
    final bytes = await _exportService.generateExportBytes(statement, format);

    final extension = switch (format.toLowerCase()) {
      'excel' => 'xlsx',
      final other => other,
    };
    final mimeType = switch (extension) {
      'csv' => MimeType.csv,
      'xlsx' => MimeType.microsoftExcel,
      'pdf' => MimeType.pdf,
      _ => MimeType.other,
    };

    final stamp = statement.generatedAt.toIso8601String().substring(0, 10);
    final name = exportFileName(statement.periodLabel, stamp);

    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: extension,
      mimeType: mimeType,
    );

    return '$name.$extension';
  }

  /// A file name the operating system will actually accept.
  ///
  /// The period label is written for a human — `هذا الشهر (أغسطس 2026)`,
  /// `2026/08/01 — 2026/08/10` — and a calendar or custom window puts a slash
  /// in it. A slash is a path separator, not a character, so the download either
  /// fails or lands somewhere nobody asked for. Everything outside the safe set
  /// collapses to an underscore, and runs of them collapse to one.
  static String exportFileName(String periodLabel, String stamp) {
    final safeLabel = periodLabel
        .replaceAll(RegExp(r'[\\/:*?"<>|()\[\]—–]'), ' ')
        .trim();
    return 'التقرير_المالي_${safeLabel}_$stamp'
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_{2,}'), '_');
  }
}
