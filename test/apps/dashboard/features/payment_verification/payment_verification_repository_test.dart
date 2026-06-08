import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/payment_verification/data/datasources/mock_booking_payment_verification_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/data/models/booking_payment_verification_model.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/data/repositories/booking_payment_verification_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/entities/booking_payment_verification.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/approve_booking_payment_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/get_booking_payment_verifications_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/reject_booking_payment_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/request_booking_payment_review_usecase.dart';

void main() {
  group('Booking payment verification clean architecture chain', () {
    test('loads verification queue with receipt and booking details', () async {
      final repository = BookingPaymentVerificationRepositoryImpl(
        MockBookingPaymentVerificationDatasource(),
      );
      final getQueue = GetBookingPaymentVerificationsUseCase(repository);

      final items = await getQueue();

      expect(items, isNotEmpty);
      expect(items.first.customer.name, 'خالد محمود');
      expect(items.first.receiptTitle, contains('إيصال'));
      expect(items.first.seatState, VerificationSeatState.temporaryReserved);
    });

    test('approval confirms selected seat permanently', () async {
      final repository = BookingPaymentVerificationRepositoryImpl(
        MockBookingPaymentVerificationDatasource(),
      );
      final getQueue = GetBookingPaymentVerificationsUseCase(repository);
      final approve = ApproveBookingPaymentUseCase(repository);

      final pending = (await getQueue()).first;
      final approved = await approve(pending.id, 'مطابق');

      expect(approved.status, BookingVerificationStatus.approved);
      expect(approved.seatState, VerificationSeatState.permanentlyConfirmed);
      expect(approved.notes.first, 'مطابق');
    });

    test(
      'rejection releases seat and review request keeps it temporary',
      () async {
        final repository = BookingPaymentVerificationRepositoryImpl(
          MockBookingPaymentVerificationDatasource(),
        );
        final getQueue = GetBookingPaymentVerificationsUseCase(repository);
        final reject = RejectBookingPaymentUseCase(repository);
        final requestReview = RequestBookingPaymentReviewUseCase(repository);

        final items = await getQueue();
        final rejected = await reject(items.first.id, 'إيصال غير مطابق');
        expect(rejected.status, BookingVerificationStatus.rejected);
        expect(rejected.seatState, VerificationSeatState.released);

        final reviewed = await requestReview(items[1].id, 'الصورة غير واضحة');
        expect(reviewed.status, BookingVerificationStatus.reviewRequested);
        expect(reviewed.seatState, VerificationSeatState.temporaryReserved);
      },
    );

    test('maps datasource failures to Arabic repository error', () async {
      final repository = BookingPaymentVerificationRepositoryImpl(
        _FailingVerificationDatasource(),
      );
      final getQueue = GetBookingPaymentVerificationsUseCase(repository);

      expect(
        getQueue.call,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل قائمة التحقق'),
          ),
        ),
      );
    });
  });
}

class _FailingVerificationDatasource
    implements BookingPaymentVerificationDatasource {
  @override
  Future<BookingPaymentVerificationModel> addNote(
    String verificationId,
    String note,
  ) {
    throw StateError('failure');
  }

  @override
  Future<BookingPaymentVerificationModel> approve(
    String verificationId,
    String note,
  ) {
    throw StateError('failure');
  }

  @override
  Future<List<BookingPaymentVerificationModel>> fetchQueue() {
    throw StateError('failure');
  }

  @override
  Future<BookingPaymentVerificationModel> reject(
    String verificationId,
    String note,
  ) {
    throw StateError('failure');
  }

  @override
  Future<BookingPaymentVerificationModel> requestReview(
    String verificationId,
    String note,
  ) {
    throw StateError('failure');
  }
}
