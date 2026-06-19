import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/payment_verification/data/repositories/booking_payment_verification_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/add_booking_payment_note_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/approve_booking_payment_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/get_booking_payment_verifications_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/reject_booking_payment_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/request_booking_payment_review_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/presentation/cubit/payment_verification_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/presentation/screens/payment_verification_screen.dart';

import 'fake_booking_payment_verification_datasource.dart';

void main() {
  testWidgets('PaymentVerificationScreen renders compact layout safely', (
    tester,
  ) async {
    final repository = BookingPaymentVerificationRepositoryImpl(
      FakeBookingPaymentVerificationDatasource(),
    );
    final cubit = PaymentVerificationCubit(
      getQueue: GetBookingPaymentVerificationsUseCase(repository),
      approve: ApproveBookingPaymentUseCase(repository),
      reject: RejectBookingPaymentUseCase(repository),
      requestReview: RequestBookingPaymentReviewUseCase(repository),
      addNote: AddBookingPaymentNoteUseCase(repository),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 800,
              child: BlocProvider.value(
                value: cubit..load(),
                child: const PaymentVerificationScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تحقق مدفوعات الحجوزات'), findsOneWidget);
    expect(find.text('قائمة المراجعة'), findsOneWidget);
    expect(find.text('خالد محمود'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await cubit.close();
  });
}
