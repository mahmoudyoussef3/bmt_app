import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/finance_payment.dart';
import '../../domain/usecases/add_payment_note_usecase.dart';
import '../../domain/usecases/get_finance_payments_usecase.dart';
import '../../domain/usecases/update_payment_review_status_usecase.dart';
import 'payments_state.dart';

class PaymentsCubit extends Cubit<PaymentsState> {
  final GetFinancePaymentsUseCase _getPayments;
  final UpdatePaymentReviewStatusUseCase _updateStatus;
  final AddPaymentNoteUseCase _addNote;

  PaymentsCubit({
    required GetFinancePaymentsUseCase getPayments,
    required UpdatePaymentReviewStatusUseCase updateStatus,
    required AddPaymentNoteUseCase addNote,
  }) : _getPayments = getPayments,
       _updateStatus = updateStatus,
       _addNote = addNote,
       super(const PaymentsLoading());

  Future<void> load() async {
    emit(const PaymentsLoading());
    try {
      final payments = await _getPayments();
      emit(
        PaymentsLoaded(
          payments: payments,
          selectedPaymentId: payments.isEmpty ? '' : payments.first.id,
        ),
      );
    } catch (error) {
      emit(PaymentsError(error.toString()));
    }
  }

  void selectPayment(String paymentId) {
    final current = state;
    if (current is! PaymentsLoaded) return;
    emit(current.copyWith(selectedPaymentId: paymentId, receiptZoom: 1));
  }

  void setReceiptZoom(double value) {
    final current = state;
    if (current is! PaymentsLoaded) return;
    emit(current.copyWith(receiptZoom: value.clamp(0.8, 1.8).toDouble()));
  }

  Future<void> updateStatus(
    FinancePayment payment,
    PaymentReviewStatus status,
  ) async {
    final current = state;
    if (current is! PaymentsLoaded) return;
    try {
      final updated = await _updateStatus(payment.id, status);
      _emitUpdated(current, updated);
    } catch (error) {
      emit(PaymentsError(error.toString()));
    }
  }

  Future<void> addNote(FinancePayment payment, String note) async {
    final normalizedNote = note.trim();
    if (normalizedNote.isEmpty) return;

    final current = state;
    if (current is! PaymentsLoaded) return;
    try {
      final updated = await _addNote(payment.id, normalizedNote);
      _emitUpdated(current, updated);
    } catch (error) {
      emit(PaymentsError(error.toString()));
    }
  }

  void _emitUpdated(PaymentsLoaded current, FinancePayment updated) {
    final payments = current.payments
        .map((payment) => payment.id == updated.id ? updated : payment)
        .toList();
    emit(current.copyWith(payments: payments, selectedPaymentId: updated.id));
  }
}
