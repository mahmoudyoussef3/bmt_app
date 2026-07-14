import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_state.dart';

import 'payment_fakes.dart';

void main() {
  group('loadCheckout', () {
    test('preselects the recommended method', () async {
      final cubit = cubitFor(FakePaymentRepository());
      addTearDown(cubit.close);

      await cubit.loadCheckout();

      final state = cubit.state as PaymentCheckoutLoaded;
      expect(state.selectedMethod, PaymentMethodType.creditCard);
      expect(state.requiresReceipt, isFalse);
    });

    test('falls back to the first method when none is recommended', () async {
      final cubit = cubitFor(
        FakePaymentRepository(methods: const [instapayMethod, walletMethod]),
      );
      addTearDown(cubit.close);

      await cubit.loadCheckout();

      final state = cubit.state as PaymentCheckoutLoaded;
      expect(state.selectedMethod, PaymentMethodType.instapay);
      expect(state.requiresReceipt, isTrue);
    });

    test('reports failure instead of showing an empty checkout', () async {
      final cubit = cubitFor(FakePaymentRepository(methodsThrow: true));
      addTearDown(cubit.close);

      await cubit.loadCheckout();

      expect(cubit.state, isA<PaymentError>());
    });
  });

  group('applyPromo', () {
    test('applies a valid code', () async {
      final cubit = cubitFor(
        FakePaymentRepository(discounts: const {'WELCOME10': 25}),
      );
      addTearDown(cubit.close);
      await cubit.loadCheckout();

      await cubit.applyPromo('welcome10');

      final state = cubit.state as PaymentCheckoutLoaded;
      expect(state.promoStatus, PromoStatus.applied);
      expect(state.promoCode, 'WELCOME10');
      expect(state.promoDiscount, 25);
    });

    test(
      'a rejected code drops the earlier discount and is named as itself',
      () async {
        // Regression: the old state could not clear a field, so a rejected code
        // left the previously accepted one on screen — checkout read
        // "WELCOME10 not valid" while the discount silently disappeared.
        final cubit = cubitFor(
          FakePaymentRepository(discounts: const {'WELCOME10': 25}),
        );
        addTearDown(cubit.close);
        await cubit.loadCheckout();
        await cubit.applyPromo('WELCOME10');

        await cubit.applyPromo('BOGUS');

        final state = cubit.state as PaymentCheckoutLoaded;
        expect(state.promoStatus, PromoStatus.invalid);
        expect(state.promoCode, 'BOGUS');
        expect(state.promoDiscount, 0);
      },
    );

    test('a promo lookup that throws does not break checkout', () async {
      final cubit = cubitFor(FakePaymentRepository(promoThrows: true));
      addTearDown(cubit.close);
      await cubit.loadCheckout();

      await cubit.applyPromo('ANYTHING');

      final state = cubit.state as PaymentCheckoutLoaded;
      expect(state.promoStatus, PromoStatus.invalid);
      expect(state.promoDiscount, 0);
    });

    test('clearing a promo restores the full fare', () async {
      final cubit = cubitFor(
        FakePaymentRepository(discounts: const {'WELCOME10': 25}),
      );
      addTearDown(cubit.close);
      await cubit.loadCheckout();
      await cubit.applyPromo('WELCOME10');

      cubit.clearPromo();

      final state = cubit.state as PaymentCheckoutLoaded;
      expect(state.promoStatus, PromoStatus.none);
      expect(state.promoCode, isNull);
      expect(state.promoDiscount, 0);
    });

    test('keeps the chosen method when a promo is applied', () async {
      final cubit = cubitFor(
        FakePaymentRepository(discounts: const {'WELCOME10': 25}),
      );
      addTearDown(cubit.close);
      await cubit.loadCheckout();
      cubit.selectMethod(PaymentMethodType.instapay);

      await cubit.applyPromo('WELCOME10');

      final state = cubit.state as PaymentCheckoutLoaded;
      expect(state.selectedMethod, PaymentMethodType.instapay);
      expect(state.requiresReceipt, isTrue);
    });
  });
}
