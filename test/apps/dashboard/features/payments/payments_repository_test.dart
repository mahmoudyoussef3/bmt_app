import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/payments/data/datasources/mock_payments_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/payments/data/repositories/payments_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/payments/domain/entities/finance_payment.dart';

void main() {
  group('PaymentsRepositoryImpl', () {
    test('loads dummy finance payments', () async {
      final repository = PaymentsRepositoryImpl(MockPaymentsDatasource());

      final payments = await repository.getPayments();

      expect(payments, isNotEmpty);
      expect(payments.first.status, PaymentReviewStatus.pendingReview);
      expect(payments.first.referenceNumber, isNotEmpty);
    });

    test('updates payment status and appends history', () async {
      final repository = PaymentsRepositoryImpl(MockPaymentsDatasource());
      final payment = (await repository.getPayments()).first;

      final updated = await repository.updateStatus(
        payment.id,
        PaymentReviewStatus.accepted,
      );

      expect(updated.status, PaymentReviewStatus.accepted);
      expect(updated.history.first.title, contains('مقبول'));
    });

    test('adds note and records timeline action', () async {
      final repository = PaymentsRepositoryImpl(MockPaymentsDatasource());
      final payment = (await repository.getPayments()).first;

      final updated = await repository.addNote(payment.id, 'تمت المطابقة');

      expect(updated.notes.first, 'تمت المطابقة');
      expect(updated.history.first.title, 'إضافة ملاحظة');
    });

    test('maps datasource load errors to Arabic message', () async {
      final repository = PaymentsRepositoryImpl(_FailingPaymentsDatasource());

      expect(
        repository.getPayments,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل المدفوعات'),
          ),
        ),
      );
    });
  });
}

class _FailingPaymentsDatasource implements PaymentsDatasource {
  @override
  Future<FinancePayment> addNote(String paymentId, String note) {
    throw StateError('failed');
  }

  @override
  Future<List<FinancePayment>> fetchPayments() {
    throw StateError('failed');
  }

  @override
  Future<FinancePayment> updateStatus(
    String paymentId,
    PaymentReviewStatus status,
  ) {
    throw StateError('failed');
  }
}
