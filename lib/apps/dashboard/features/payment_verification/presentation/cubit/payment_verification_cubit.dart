import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_payment_verification.dart';
import '../../domain/usecases/add_booking_payment_note_usecase.dart';
import '../../domain/usecases/approve_booking_payment_usecase.dart';
import '../../domain/usecases/get_booking_payment_verifications_usecase.dart';
import '../../domain/usecases/reject_booking_payment_usecase.dart';
import '../../domain/usecases/request_booking_payment_review_usecase.dart';
import 'payment_verification_state.dart';

class PaymentVerificationCubit extends Cubit<PaymentVerificationState> {
  final GetBookingPaymentVerificationsUseCase _getQueue;
  final ApproveBookingPaymentUseCase _approve;
  final RejectBookingPaymentUseCase _reject;
  final RequestBookingPaymentReviewUseCase _requestReview;
  final AddBookingPaymentNoteUseCase _addNote;

  PaymentVerificationCubit({
    required GetBookingPaymentVerificationsUseCase getQueue,
    required ApproveBookingPaymentUseCase approve,
    required RejectBookingPaymentUseCase reject,
    required RequestBookingPaymentReviewUseCase requestReview,
    required AddBookingPaymentNoteUseCase addNote,
  }) : _getQueue = getQueue,
       _approve = approve,
       _reject = reject,
       _requestReview = requestReview,
       _addNote = addNote,
       super(const PaymentVerificationLoading());

  Future<void> load() async {
    final previous = state;
    if (previous is! PaymentVerificationLoaded) {
      emit(const PaymentVerificationLoading());
    } else {
      emit(
        previous.copyWith(isSaving: true, clearError: true, clearMessage: true),
      );
    }
    try {
      final items = await _getQueue();
      final previousSelectedId = previous is PaymentVerificationLoaded
          ? previous.selectedId
          : '';
      final selectedId = items.any((item) => item.id == previousSelectedId)
          ? previousSelectedId
          : items.isEmpty
          ? ''
          : items.first.id;
      emit(
        PaymentVerificationLoaded(
          items: items,
          selectedId: selectedId,
          filter: previous is PaymentVerificationLoaded
              ? previous.filter
              : PaymentVerificationFilter.all,
          query: previous is PaymentVerificationLoaded ? previous.query : '',
        ),
      );
    } catch (error) {
      if (previous is PaymentVerificationLoaded) {
        emit(
          previous.copyWith(
            isSaving: false,
            errorMessage: error.toString(),
            clearMessage: true,
          ),
        );
      } else {
        emit(PaymentVerificationError(error.toString()));
      }
    }
  }

  void select(String verificationId) {
    final current = state;
    if (current is! PaymentVerificationLoaded) return;
    emit(
      current.copyWith(
        selectedId: verificationId,
        receiptZoom: 1,
        clearMessage: true,
        clearError: true,
      ),
    );
  }

  void setReceiptZoom(double value) {
    final current = state;
    if (current is! PaymentVerificationLoaded) return;
    emit(current.copyWith(receiptZoom: value.clamp(0.8, 2.2).toDouble()));
  }

  void setFilter(PaymentVerificationFilter filter) {
    final current = state;
    if (current is! PaymentVerificationLoaded) return;
    final filtered = current.copyWith(filter: filter, clearMessage: true);
    final selectedId = filtered.selectedItem?.id ?? '';
    emit(filtered.copyWith(selectedId: selectedId));
  }

  void setQuery(String query) {
    final current = state;
    if (current is! PaymentVerificationLoaded) return;
    final filtered = current.copyWith(query: query, clearMessage: true);
    final selectedId = filtered.selectedItem?.id ?? '';
    emit(filtered.copyWith(selectedId: selectedId));
  }

  void clearFeedback() {
    final current = state;
    if (current is! PaymentVerificationLoaded) return;
    emit(current.copyWith(clearMessage: true, clearError: true));
  }

  Future<void> approve(
    BookingPaymentVerification verification,
    String note,
  ) async {
    await _mutate(
      () => _approve(verification.id, note),
      successMessage: 'تم اعتماد الدفع وتثبيت المقعد.',
    );
  }

  Future<void> reject(
    BookingPaymentVerification verification,
    String note,
  ) async {
    await _mutate(
      () => _reject(verification.id, note),
      successMessage: 'تم رفض الدفع وتحرير المقعد.',
    );
  }

  Future<void> requestReview(
    BookingPaymentVerification verification,
    String note,
  ) async {
    await _mutate(
      () => _requestReview(verification.id, note),
      successMessage: 'تم طلب مراجعة أو إعادة رفع من العميل.',
    );
  }

  Future<void> addNote(
    BookingPaymentVerification verification,
    String note,
  ) async {
    final normalized = note.trim();
    if (normalized.isEmpty) return;
    await _mutate(
      () => _addNote(verification.id, normalized),
      successMessage: 'تمت إضافة الملاحظة.',
    );
  }

  Future<void> _mutate(
    Future<BookingPaymentVerification> Function() action, {
    required String successMessage,
  }) async {
    final current = state;
    if (current is! PaymentVerificationLoaded) return;
    emit(
      current.copyWith(isSaving: true, clearMessage: true, clearError: true),
    );
    try {
      final updated = await action();
      final items = current.items
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      emit(
        current.copyWith(
          items: items,
          selectedId: updated.id,
          isSaving: false,
          message: successMessage,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isSaving: false,
          errorMessage: error.toString(),
          clearMessage: true,
        ),
      );
    }
  }
}
