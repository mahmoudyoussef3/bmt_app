import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
import '../../../../core/session/dashboard_session.dart';
import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import '../models/wallet_models.dart';
import 'wallet_datasource.dart';

/// Every wallet read and every wallet write, over the RPC surface.
///
/// ## Why nothing here is a table write
///
/// Neither `wallets` nor `wallet_transactions` carries an INSERT, UPDATE or
/// DELETE policy for any role, so RLS alone denies every mutation from this
/// client. The only path to money movement is a SECURITY DEFINER RPC, which is
/// what makes the guards — capability, self-dealing, caps, cumulative refund
/// limits, the wallet lock — unbypassable rather than merely present.
///
/// ## Why the office id is never sent
///
/// Every RPC resolves the office from `current_office_id()` server-side and
/// refuses to accept one as a parameter. There is therefore no office id to get
/// wrong, and no cross-office request this class is capable of making.
class SupabaseWalletDatasource implements WalletDatasource {
  final SupabaseClient _client;
  final DashboardSession _session;

  const SupabaseWalletDatasource(this._client, this._session);

  @override
  Future<WalletOverview> fetchOverview() async {
    try {
      final json = await _client.rpc('office_wallet_overview');
      return WalletMapper.overview(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WalletDirectoryPage> fetchDirectory({
    String? search,
    required int limit,
    required int offset,
  }) async {
    try {
      final json = await _client.rpc(
        'office_wallet_directory',
        params: {
          'p_search': (search?.trim().isEmpty ?? true) ? null : search!.trim(),
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return WalletMapper.directory(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WalletSummary> fetchSummary(String clientId) async {
    try {
      final json = await _client.rpc(
        'office_wallet_summary',
        params: {'p_client_id': clientId},
      );
      return WalletMapper.summary(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WalletLedgerPage> fetchLedger({
    required Map<String, dynamic> filters,
    required int limit,
    required int offset,
  }) async {
    try {
      final json = await _client.rpc(
        'office_wallet_ledger',
        params: {'p_filters': filters, 'p_limit': limit, 'p_offset': offset},
      );
      return WalletMapper.ledger(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<RefundRequest>> fetchRefundQueue(
    List<RefundStatus> statuses,
  ) async {
    try {
      
      final rows = await _client
          .from('refund_requests')
          .select('''
            id, client_id, booking_id, trip_id, amount, approved_amount, currency,
            status, category, reason, notes, source, settlement_method, settled_at,
            wallet_transaction_id, external_transaction_id,
            trip_cancellation_batch_id, requested_by_name, reviewed_by_name,
            reviewed_at, created_at,
            client:clients(full_name, phone),
            booking:operation_bookings(booking_number)
          ''')
          .eq('office_id', _session.officeId)
          .inFilter('status', statuses.map((s) => s.dbValue).toList())
          .order('created_at', ascending: false)
          .limit(300);

      return (rows as List)
          .map((row) => WalletMapper.refund(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<RefundableBooking>> fetchRefundableBookings(
    String clientId,
  ) async {
    try {
      final json = await _client.rpc(
        'office_wallet_refundable_bookings',
        params: {'p_client_id': clientId},
      );
      return (json as List)
          .map((row) => WalletMapper.refundableBooking(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<CancelledTripRefundTarget>>
  fetchCancelledTripsWithRefunds() async {
    try {
      final json = await _client.rpc('office_cancelled_trips_with_refunds');
      return (json as List)
          .map((row) => WalletMapper.cancelledTrip(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WalletTransaction> postAdjustment({
    required WalletKind kind,
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) async {
    
    final function = switch (kind) {
      WalletKind.cashback => 'office_wallet_cashback',
      WalletKind.manualCredit => 'office_wallet_credit',
      WalletKind.manualDebit => 'office_wallet_debit',
      _ => throw ArgumentError('Unsupported adjustment kind: $kind'),
    };

    try {
      final json = await _client.rpc(
        function,
        params: {
          'p_client_id': clientId,
          'p_amount': amount,
          'p_category': category,
          'p_reason': reason,
          'p_notes': notes,
          'p_request_key': requestKey,
        },
      );
      return WalletMapper.transaction(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WalletTransaction> reverseTransaction({
    required String transactionId,
    required String reason,
    required String category,
    required String requestKey,
  }) async {
    try {
      final json = await _client.rpc(
        'office_wallet_reverse',
        params: {
          'p_transaction_id': transactionId,
          'p_reason': reason,
          'p_request_key': requestKey,
          'p_category': category,
        },
      );
      return WalletMapper.transaction(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Wallet> setWalletStatus({
    required String clientId,
    required WalletStatus status,
    required String reason,
  }) async {
    try {
      final json = await _client.rpc(
        'office_wallet_set_status',
        params: {
          'p_client_id': clientId,
          'p_status': status.dbValue,
          'p_reason': reason,
        },
      );
      return WalletMapper.walletRow(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WalletChainVerification> verifyChain(String clientId) async {
    try {
      final json = await _client.rpc(
        'office_wallet_verify_chain',
        params: {'p_client_id': clientId},
      );
      return WalletMapper.chain(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<RefundRequest> createRefund({
    required String bookingId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required RefundSettlement settlement,
    required String requestKey,
  }) async {
    try {
      final json = await _client.rpc(
        'office_refund_create',
        params: {
          'p_booking_id': bookingId,
          'p_amount': amount,
          'p_category': category,
          'p_reason': reason,
          'p_notes': notes,
          'p_settlement_method': settlement.dbValue,
          'p_request_key': requestKey,
        },
      );
      return WalletMapper.refund(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<RefundRequest> decideRefund({
    required String refundId,
    required bool approve,
    double? approvedAmount,
    required RefundSettlement settlement,
    String? reason,
    required String requestKey,
  }) async {
    try {
      final json = await _client.rpc(
        'office_refund_decide',
        params: {
          'p_refund_id': refundId,
          'p_decision': approve ? 'approve' : 'reject',
          'p_approved_amount': approvedAmount,
          'p_settlement_method': settlement.dbValue,
          'p_reason': reason,
          'p_request_key': requestKey,
        },
      );
      return WalletMapper.refund(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<TripBatchRefundResult> refundTripBatch({
    required String tripId,
    required String category,
    required String reason,
    required RefundSettlement settlement,
    required String requestKey,
  }) async {
    try {
      final json = await _client.rpc(
        'office_refund_trip_batch',
        params: {
          'p_trip_id': tripId,
          'p_category': category,
          'p_reason': reason,
          'p_settlement_method': settlement.dbValue,
          'p_request_key': requestKey,
        },
      );
      return WalletMapper.batchResult(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Turns the server's machine codes into the sentence the operator needs.
  ///
  /// These are not generic error strings: each one names a specific control that
  /// fired, and an operator who is told "this booking has already been fully
  /// refunded" stops, while one told "database error 23514" calls support.
  Exception _handleError(dynamic error) {
    
    LicensingGuard.check(error);

    if (error is PostgrestException) {
      final message = error.message;
      final translated = _messages.entries
          .where((entry) => message.contains(entry.key))
          .map((entry) => entry.value)
          .firstOrNull;
      if (translated != null) return Exception(translated);
      return Exception('خطأ بقاعدة البيانات: $message');
    }
    return Exception(error.toString().replaceAll('Exception: ', ''));
  }

  static const Map<String, String> _messages = {
    'not_an_office_user': 'حسابك غير مرتبط بمكتب.',
    'not_authorized': 'ليس لديك صلاحية تنفيذ هذه العملية.',
    'self_adjustment_denied':
        'لا يمكنك تعديل رصيد حسابك الشخصي. يجب أن ينفّذها مستخدم آخر.',
    'client_not_in_office': 'هذا العميل ليس من عملاء مكتبك.',
    'invalid_amount': 'المبلغ غير صالح.',
    'amount_exceeds_policy':
        'المبلغ يتجاوز الحد المسموح للعملية الواحدة في إعدادات المكتب.',
    'reason_required': 'سبب العملية مطلوب.',
    'invalid_category': 'التصنيف غير صالح لهذا النوع من العمليات.',
    'request_key_conflict':
        'تم استخدام نفس مفتاح العملية ببيانات مختلفة. أعد فتح النافذة وحاول مجددًا.',
    'refund_exceeds_payment': 'المبلغ أكبر من المتبقي القابل للرد على هذا الحجز.',
    'adjustment_rate_limited':
        'تم تجاوز عدد العمليات المسموح بها في الساعة. حاول لاحقًا.',
    'daily_cap_exceeded': 'تم تجاوز الحد اليومي للحوافز لهذا المستخدم.',
    'wallet_frozen': 'المحفظة مجمّدة — لا يمكن الخصم منها.',
    'insufficient_wallet_balance': 'الرصيد المتاح لا يكفي لتنفيذ هذه العملية.',
    'already_reversed': 'تم عكس هذه العملية بالفعل.',
    'cannot_reverse_reversal': 'لا يمكن عكس عملية عكسية.',
    'transaction_not_found': 'لم يتم العثور على العملية.',
    'refund_not_found': 'لم يتم العثور على طلب الاسترداد.',
    'refund_not_actionable': 'تم البتّ في هذا الطلب بالفعل.',
    'guest_booking_no_wallet':
        'هذا الحجز بدون حساب عميل — لا توجد محفظة. اختر طريقة تسوية أخرى.',
    'invalid_settlement_method': 'طريقة التسوية غير صالحة.',
    'cross_office_denied': 'هذا السجل يخص مكتبًا آخر.',
    'booking_not_found': 'لم يتم العثور على الحجز.',
    'trip_not_found': 'لم يتم العثور على الرحلة.',
    'wallet_not_found': 'لا توجد محفظة لهذا العميل بعد.',
    'wallet_ledger_immutable': 'سجل المحفظة غير قابل للتعديل.',
    'wallet_balance_requires_ledger_entry':
        'لا يمكن تعديل الرصيد بدون حركة مسجّلة في السجل.',
  };
}
