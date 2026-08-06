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
    final name = 'التقرير_المالي_${statement.periodLabel}_$stamp'.replaceAll(
      ' ',
      '_',
    );

    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: extension,
      mimeType: mimeType,
    );

    return '$name.$extension';
  }
}
