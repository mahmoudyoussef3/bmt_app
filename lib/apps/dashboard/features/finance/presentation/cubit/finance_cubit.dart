import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/finance_entities.dart';
import '../../domain/usecases/export_finance_statement_usecase.dart';
import '../../domain/usecases/get_payments_usecase.dart';
import '../../domain/usecases/get_refund_requests_usecase.dart';
import '../../domain/usecases/get_subscriptions_usecase.dart';
import '../../domain/usecases/get_wallet_position_usecase.dart';
import 'finance_state.dart';

/// Finance reads money and explains it. There is no approve, reject, cancel or
/// verify here on purpose — those decisions belong to Bookings, and a reporting
/// screen that can also change the numbers it reports is a screen nobody can
/// trust.
class FinanceCubit extends Cubit<FinanceState> {
  final GetPaymentsUseCase _getPayments;
  final GetRefundRequestsUseCase _getRefundRequests;
  final GetFinanceSubscriptionsUseCase _getSubscriptions;
  final GetWalletPositionUseCase _getWalletPosition;
  final ExportFinanceStatementUseCase _exportStatement;

  FinanceCubit({
    required GetPaymentsUseCase getPayments,
    required GetRefundRequestsUseCase getRefundRequests,
    required GetFinanceSubscriptionsUseCase getSubscriptions,
    required GetWalletPositionUseCase getWalletPosition,
    required ExportFinanceStatementUseCase exportStatement,
  }) : _getPayments = getPayments,
       _getRefundRequests = getRefundRequests,
       _getSubscriptions = getSubscriptions,
       _getWalletPosition = getWalletPosition,
       _exportStatement = exportStatement,
       super(const FinanceLoading());

  Future<void> load() async {
    
    final current = state;
    final period = current is FinanceLoaded
        ? current.period
        : FinancePeriod.month;
    final customRange = current is FinanceLoaded ? current.customRange : null;

    emit(const FinanceLoading());
    try {
      
      final (payments, refunds, subscriptions, wallet) = await (
        _getPayments(),
        _getRefundRequests(),
        _getSubscriptions(),
        _getWalletPosition(),
      ).wait;

      emit(
        FinanceLoaded(
          ledger: FinanceLedger.build(
            payments: payments,
            subscriptions: subscriptions,
          ),
          refundRequests: refunds,
          subscriptions: subscriptions,
          walletPosition: wallet,
          loadedAt: DateTime.now(),
          period: period,
          customRange: customRange,
          ledgerCapReached: payments.length >= FinanceLedger.rowCap,
        ),
      );
    } catch (error) {
      emit(FinanceError(error.toString()));
    }
  }

  void selectSection(FinanceSection section) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(current.copyWith(section: section, clearActionMessage: true));
  }

  /// Changing the window re-derives every figure on the screen at once — the
  /// point of holding the whole ledger in state.
  void setPeriod(FinancePeriod period) {
    final current = state;
    if (current is! FinanceLoaded) return;
    
    // Selecting "فترة مخصصة" with no range yet would resolve to the default
    // window and quietly disagree with its own chip, so the picker owns that
    // transition and this refuses it.
    if (period == FinancePeriod.custom && current.customRange == null) return;
    emit(current.copyWith(period: period, ledgerPage: 0));
  }

  /// Applies an operator-chosen range. [start] and [end] are days; the window is
  /// widened to cover both of them completely, because an owner who picks
  /// "1 — 31" means the whole of the 31st.
  void setCustomRange(DateTime start, DateTime end) {
    final current = state;
    if (current is! FinanceLoaded) return;

    final (from, to) = start.isAfter(end) ? (end, start) : (start, end);
    emit(
      current.copyWith(
        period: FinancePeriod.custom,
        customRange: FinanceDateRange(
          start: DateTime(from.year, from.month, from.day),
          end: DateTime(to.year, to.month, to.day, 23, 59, 59, 999),
        ),
        ledgerPage: 0,
      ),
    );
  }

  void setLedgerSort(FinanceLedgerSort sort) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(current.copyWith(ledgerSort: sort, ledgerPage: 0));
  }

  void setSearchQuery(String query) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(current.copyWith(searchQuery: query, ledgerPage: 0));
  }

  void setTypeFilter(FinanceEntryType? type) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(
      type == null
          ? current.copyWith(clearTypeFilter: true, ledgerPage: 0)
          : current.copyWith(typeFilter: type, ledgerPage: 0),
    );
  }

  void setMethodFilter(FinancePaymentMethod? method) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(
      method == null
          ? current.copyWith(clearMethodFilter: true, ledgerPage: 0)
          : current.copyWith(methodFilter: method, ledgerPage: 0),
    );
  }

  void setStatusFilter(PaymentStatus? status) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(
      status == null
          ? current.copyWith(clearStatusFilter: true, ledgerPage: 0)
          : current.copyWith(statusFilter: status, ledgerPage: 0),
    );
  }

  void clearFilters() {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(
      current.copyWith(
        searchQuery: '',
        clearTypeFilter: true,
        clearMethodFilter: true,
        clearStatusFilter: true,
        ledgerPage: 0,
      ),
    );
  }

  void setLedgerPage(int page) {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(current.copyWith(ledgerPage: page < 0 ? 0 : page));
  }

  void clearActionMessage() {
    final current = state;
    if (current is! FinanceLoaded) return;
    emit(current.copyWith(clearActionMessage: true));
  }

  /// Exports the current window's statement. A failure keeps the loaded screen
  /// and reports itself as a message — losing the operator's period and filters
  /// because a download failed would be the worse outcome.
  Future<void> exportStatement(String format) async {
    final current = state;
    if (current is! FinanceLoaded) return;

    emit(current.copyWith(exporting: true, clearActionMessage: true));
    try {
      final fileName = await _exportStatement(
        current.analytics.toStatement(generatedAt: DateTime.now()),
        format,
      );
      emit(
        current.copyWith(
          exporting: false,
          actionMessage: 'تم تصدير التقرير: $fileName',
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          exporting: false,
          actionMessage: 'تعذر تصدير التقرير: $error',
        ),
      );
    }
  }
}
