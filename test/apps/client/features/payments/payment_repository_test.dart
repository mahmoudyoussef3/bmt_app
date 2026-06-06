import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/payments/data/datasources/mock_payment_datasource.dart';
import 'package:bmt_app/apps/client/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/apply_promo_code_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/generate_payment_reference_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/get_payment_methods_usecase.dart';

void main() {
  group('Client payments', () {
    late PaymentRepositoryImpl repository;

    setUp(() {
      repository = const PaymentRepositoryImpl(MockPaymentDatasource());
    });

    test('returns supported payment methods', () async {
      final methods = await GetPaymentMethodsUseCase(repository)();

      expect(methods, hasLength(5));
      expect(methods.first.type, PaymentMethodType.creditCard);
      expect(methods.first.recommended, isTrue);
      expect(methods.last.type, PaymentMethodType.walletBalance);
    });

    test('applies known promo codes and rejects unknown codes', () {
      const applyPromo = ApplyPromoCodeUseCase();

      expect(applyPromo('welcome10'), 10);
      expect(applyPromo('MEGA20'), 20);
      expect(applyPromo('NOPE'), 0);
    });

    test('calculates checkout totals and wallet remainder', () {
      const data = PaymentCheckoutData(
        pickupPoint: 'Banha Station',
        destination: 'Smart Village',
        vehicleNumber: 'MB-15-2847',
        departureTime: '8:40 AM',
        arrivalTime: '9:20 AM',
        selectedSeat: '6',
        driverName: 'Ahmed Mohamed',
      );

      expect(data.subtotal, 68);
      expect(data.totalForDiscount(10), 58);
      expect(data.remainingWalletAfterPayment(58), 192);
    });

    test('generates deterministic references when seeded', () {
      final generate = GeneratePaymentReferenceUseCase(random: Random(42));

      expect(generate(prefix: 'TXN'), 'TXN-2026-VQE7X');
    });
  });
}
