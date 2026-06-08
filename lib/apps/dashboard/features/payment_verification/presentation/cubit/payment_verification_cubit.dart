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
    emit(const PaymentVerificationLoading());
    try {
      final items = await _getQueue();
      emit(
        PaymentVerificationLoaded(
          items: items,
          selectedId: items.isEmpty ? '' : items.first.id,
        ),
      );
    } catch (error) {
      emit(PaymentVerificationError(error.toString()));
    }
  }

  void select(String verificationId) {
    final current = state;
    if (current is! PaymentVerificationLoaded) return;
    emit(current.copyWith(selectedId: verificationId, receiptZoom: 1));
  }

  void setReceiptZoom(double value) {
    final current = state;
    if (current is! PaymentVerificationLoaded) return;
    emit(current.copyWith(receiptZoom: value.clamp(0.8, 2.2).toDouble()));
  }

  Future<void> approve(
    BookingPaymentVerification verification,
    String note,
  ) async {
    await _mutate(() => _approve(verification.id, note));
  }

  Future<void> reject(
    BookingPaymentVerification verification,
    String note,
  ) async {
    await _mutate(() => _reject(verification.id, note));
  }

  Future<void> requestReview(
    BookingPaymentVerification verification,
    String note,
  ) async {
    await _mutate(() => _requestReview(verification.id, note));
  }

  Future<void> addNote(
    BookingPaymentVerification verification,
    String note,
  ) async {
    final normalized = note.trim();
    if (normalized.isEmpty) return;
    await _mutate(() => _addNote(verification.id, normalized));
  }

  Future<void> _mutate(
    Future<BookingPaymentVerification> Function() action,
  ) async {
    final current = state;
    if (current is! PaymentVerificationLoaded) return;
    try {
      final updated = await action();
      final items = current.items
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      emit(current.copyWith(items: items, selectedId: updated.id));
    } catch (error) {
      emit(PaymentVerificationError(error.toString()));
    }
  }
}
