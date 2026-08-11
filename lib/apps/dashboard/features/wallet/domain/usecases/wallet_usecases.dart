import '../entities/refund_request.dart';
import '../entities/wallet.dart';
import '../entities/wallet_summary.dart';
import '../entities/wallet_transaction.dart';
import '../entities/wallet_vocabulary.dart';
import '../repositories/wallet_repository.dart';

/// Raised when a request is refused before it ever reaches the database.
///
/// The server enforces every one of these rules too — it has to, because the UI
/// is not a security boundary. Checking them here as well is about the operator:
/// a caught mistake explained in Arabic, in the dialog, beats a round trip that
/// comes back saying `invalid_amount`.
class WalletRuleViolation implements Exception {
  final String message;

  const WalletRuleViolation(this.message);

  @override
  String toString() => message;
}

/// The whole module's landing read: the header strip plus the first page of the
/// customer directory, fetched together because a screen that shows one without
/// the other is a screen mid-load.
class GetWalletWorkspaceUseCase {
  final WalletRepository _repository;

  const GetWalletWorkspaceUseCase(this._repository);

  Future<({WalletOverview overview, WalletDirectoryPage directory})> call({
    String? search,
    int limit = 60,
  }) async {
    final results = await Future.wait([
      _repository.getOverview(),
      _repository.getDirectory(search: search, limit: limit, offset: 0),
    ]);
    return (
      overview: results[0] as WalletOverview,
      directory: results[1] as WalletDirectoryPage,
    );
  }
}

class SearchWalletDirectoryUseCase {
  final WalletRepository _repository;

  const SearchWalletDirectoryUseCase(this._repository);

  Future<WalletDirectoryPage> call({
    String? search,
    int limit = 60,
    int offset = 0,
  }) => _repository.getDirectory(search: search, limit: limit, offset: offset);
}

class GetWalletSummaryUseCase {
  final WalletRepository _repository;

  const GetWalletSummaryUseCase(this._repository);

  Future<WalletSummary> call(String clientId) =>
      _repository.getSummary(clientId);
}

class GetWalletLedgerUseCase {
  final WalletRepository _repository;

  const GetWalletLedgerUseCase(this._repository);

  Future<WalletLedgerPage> call({
    WalletLedgerFilters filters = const WalletLedgerFilters(),
    int limit = 100,
    int offset = 0,
  }) => _repository.getLedger(filters: filters, limit: limit, offset: offset);
}

class GetRefundQueueUseCase {
  final WalletRepository _repository;

  const GetRefundQueueUseCase(this._repository);

  Future<List<RefundRequest>> call({
    List<RefundStatus> statuses = const [
      RefundStatus.pending,
      RefundStatus.approved,
    ],
  }) => _repository.getRefundQueue(statuses: statuses);
}

class GetRefundableBookingsUseCase {
  final WalletRepository _repository;

  const GetRefundableBookingsUseCase(this._repository);

  Future<List<RefundableBooking>> call(String clientId) =>
      _repository.getRefundableBookings(clientId);
}

class GetCancelledTripsUseCase {
  final WalletRepository _repository;

  const GetCancelledTripsUseCase(this._repository);

  Future<List<CancelledTripRefundTarget>> call() =>
      _repository.getCancelledTripsWithRefunds();
}

/// Cashback, manual credit and manual debit — the three adjustments, behind one
/// set of rules.
///
/// Kept as one use case rather than three because the *rules* are identical and
/// only the kind differs; splitting it would mean maintaining the same four
/// guards in three places. The kind is still closed: it is a [WalletKind], not a
/// caller-supplied string.
class AdjustWalletUseCase {
  final WalletRepository _repository;

  const AdjustWalletUseCase(this._repository);

  Future<WalletTransaction> call({
    required WalletKind kind,
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
    Wallet? wallet,
  }) {
    if (kind != WalletKind.cashback &&
        kind != WalletKind.manualCredit &&
        kind != WalletKind.manualDebit) {
      throw const WalletRuleViolation('نوع العملية غير مسموح به هنا.');
    }

    final rounded = double.parse(amount.toStringAsFixed(2));
    if (rounded <= 0) {
      throw const WalletRuleViolation('المبلغ يجب أن يكون أكبر من صفر.');
    }
    if (reason.trim().isEmpty) {
      throw const WalletRuleViolation('سبب العملية مطلوب.');
    }
    if (!WalletCategories.forKind(kind).any((c) => c.code == category)) {
      throw const WalletRuleViolation('التصنيف غير صالح لهذا النوع.');
    }

    if (kind == WalletKind.manualDebit && wallet != null) {
      if (wallet.isFrozen) {
        throw const WalletRuleViolation(
          'المحفظة مجمّدة — لا يمكن الخصم منها حتى يتم إلغاء التجميد.',
        );
      }
      if (rounded > wallet.availableBalance) {
        throw const WalletRuleViolation(
          'لا يمكن خصم مبلغ أكبر من الرصيد المتاح. الفارق يُسجَّل كمستحق خارج المحفظة.',
        );
      }
    }

    return switch (kind) {
      WalletKind.cashback => _repository.grantCashback(
        clientId: clientId,
        amount: rounded,
        category: category,
        reason: reason.trim(),
        notes: notes,
        requestKey: requestKey,
      ),
      WalletKind.manualCredit => _repository.credit(
        clientId: clientId,
        amount: rounded,
        category: category,
        reason: reason.trim(),
        notes: notes,
        requestKey: requestKey,
      ),
      _ => _repository.debit(
        clientId: clientId,
        amount: rounded,
        category: category,
        reason: reason.trim(),
        notes: notes,
        requestKey: requestKey,
      ),
    };
  }
}

/// Posts the inverse of one entry.
///
/// The three refusals below are the domain's, not the UI's: a reversal of a
/// reversal has no defined balance effect, an already-reversed entry would
/// double-count, and reversing a credit that has since been spent would force
/// the balance negative — which §2.6 rules out. In that last case the honest
/// outcome is a refusal and an out-of-band receivable, not a negative wallet.
class ReverseWalletTransactionUseCase {
  final WalletRepository _repository;

  const ReverseWalletTransactionUseCase(this._repository);

  Future<WalletTransaction> call({
    required WalletTransaction transaction,
    required String reason,
    String category = 'operator_error',
    required String requestKey,
    Wallet? wallet,
  }) {
    if (transaction.isReversal) {
      throw const WalletRuleViolation('لا يمكن عكس عملية عكسية.');
    }
    if (transaction.isReversed) {
      throw const WalletRuleViolation('هذه العملية معكوسة بالفعل.');
    }
    if (reason.trim().isEmpty) {
      throw const WalletRuleViolation('سبب العكس مطلوب.');
    }
    if (!WalletCategories.reversal.any((c) => c.code == category)) {
      throw const WalletRuleViolation('تصنيف العكس غير صالح.');
    }
    if (transaction.isCredit &&
        wallet != null &&
        transaction.amount > wallet.availableBalance) {
      throw const WalletRuleViolation(
        'تم إنفاق الرصيد بالفعل ولا يكفي لعكس العملية. اخصم المتاح وسجّل الفارق كمستحق خارج المحفظة.',
      );
    }

    return _repository.reverse(
      transactionId: transaction.id,
      reason: reason.trim(),
      category: category,
      requestKey: requestKey,
    );
  }
}

class SetWalletStatusUseCase {
  final WalletRepository _repository;

  const SetWalletStatusUseCase(this._repository);

  Future<Wallet> call({
    required String clientId,
    required WalletStatus status,
    required String reason,
  }) {
    
    if (reason.trim().isEmpty) {
      throw const WalletRuleViolation('سبب تغيير حالة المحفظة مطلوب.');
    }
    return _repository.setWalletStatus(
      clientId: clientId,
      status: status,
      reason: reason.trim(),
    );
  }
}

class VerifyWalletChainUseCase {
  final WalletRepository _repository;

  const VerifyWalletChainUseCase(this._repository);

  Future<WalletChainVerification> call(String clientId) =>
      _repository.verifyChain(clientId);
}

class CreateRefundUseCase {
  final WalletRepository _repository;

  const CreateRefundUseCase(this._repository);

  Future<RefundRequest> call({
    required RefundableBooking booking,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required RefundSettlement settlement,
    required String requestKey,
    bool hasClient = true,
  }) {
    final rounded = double.parse(amount.toStringAsFixed(2));
    if (rounded <= 0) {
      throw const WalletRuleViolation('المبلغ يجب أن يكون أكبر من صفر.');
    }
    if (rounded > booking.refundableAmount) {
      throw const WalletRuleViolation(
        'المبلغ أكبر من المتبقي القابل للرد على هذا الحجز.',
      );
    }
    if (reason.trim().isEmpty) {
      throw const WalletRuleViolation('سبب الاسترداد مطلوب.');
    }
    if (!WalletCategories.refund.any((c) => c.code == category)) {
      throw const WalletRuleViolation('تصنيف الاسترداد غير صالح.');
    }
    
    if (settlement == RefundSettlement.wallet && !hasClient) {
      throw const WalletRuleViolation(
        'هذا الحجز بدون حساب عميل — لا توجد محفظة. اختر طريقة تسوية أخرى.',
      );
    }

    return _repository.createRefund(
      bookingId: booking.bookingId,
      amount: rounded,
      category: category,
      reason: reason.trim(),
      notes: notes,
      settlement: settlement,
      requestKey: requestKey,
    );
  }
}

class DecideRefundUseCase {
  final WalletRepository _repository;

  const DecideRefundUseCase(this._repository);

  Future<RefundRequest> call({
    required RefundRequest refund,
    required bool approve,
    double? approvedAmount,
    RefundSettlement settlement = RefundSettlement.wallet,
    String? reason,
    required String requestKey,
  }) {
    if (!refund.isOpen) {
      throw const WalletRuleViolation(
        'تم البتّ في هذا الطلب بالفعل. حدّث القائمة لعرض حالته الحالية.',
      );
    }
    if (!approve && (reason == null || reason.trim().isEmpty)) {
      throw const WalletRuleViolation('سبب الرفض مطلوب.');
    }
    if (approve) {
      final amount = approvedAmount ?? refund.amount;
      if (amount <= 0) {
        throw const WalletRuleViolation('المبلغ المعتمد يجب أن يكون أكبر من صفر.');
      }
      if (amount > refund.amount) {
        throw const WalletRuleViolation(
          'لا يمكن اعتماد مبلغ أكبر من المبلغ المطلوب.',
        );
      }
      if (settlement == RefundSettlement.wallet && refund.clientId == null) {
        throw const WalletRuleViolation(
          'هذا الطلب بدون حساب عميل — اختر طريقة تسوية أخرى.',
        );
      }
    }

    return _repository.decideRefund(
      refundId: refund.id,
      approve: approve,
      approvedAmount: approve ? (approvedAmount ?? refund.amount) : null,
      settlement: settlement,
      reason: reason,
      requestKey: requestKey,
    );
  }
}

class RefundTripBatchUseCase {
  final WalletRepository _repository;

  const RefundTripBatchUseCase(this._repository);

  Future<TripBatchRefundResult> call({
    required CancelledTripRefundTarget trip,
    String category = 'trip_cancelled',
    required String reason,
    RefundSettlement settlement = RefundSettlement.wallet,
    required String requestKey,
  }) {
    if (trip.pendingBookings <= 0) {
      throw const WalletRuleViolation('لا توجد حجوزات قابلة للرد على هذه الرحلة.');
    }
    if (reason.trim().isEmpty) {
      throw const WalletRuleViolation('سبب الاسترداد مطلوب.');
    }
    if (!WalletCategories.refund.any((c) => c.code == category)) {
      throw const WalletRuleViolation('تصنيف الاسترداد غير صالح.');
    }

    return _repository.refundTripBatch(
      tripId: trip.tripId,
      category: category,
      reason: reason.trim(),
      settlement: settlement,
      requestKey: requestKey,
    );
  }
}
