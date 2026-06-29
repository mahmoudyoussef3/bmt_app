import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/payments/domain/entities/finance_payment.dart';

void main() {
  test('subscription payment source survives status updates', () {
    const payment = FinancePayment(
      id: 'subscription:sub-1',
      userName: 'عميل',
      amount: '500 ج.م',
      method: FinancePaymentMethod.bankTransfer,
      paidAt: 'اليوم',
      status: PaymentReviewStatus.pendingReview,
      user: 'عميل - 0100',
      trip: 'القاهرة - الجيزة',
      packageName: 'شهر',
      referenceNumber: 'SUB1',
      receiptLabel: 'إيصال',
      receiptMeta: 'مرفوع',
      notes: [],
      history: [],
      source: FinancePaymentSource.subscription,
    );

    final accepted = payment.copyWith(status: PaymentReviewStatus.accepted);

    expect(accepted.source, FinancePaymentSource.subscription);
    expect(accepted.status, PaymentReviewStatus.accepted);
  });
}
