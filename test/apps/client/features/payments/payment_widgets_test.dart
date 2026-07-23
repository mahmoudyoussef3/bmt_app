import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_state.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_method_picker.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_pay_bar.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_promo_field.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

const _wallet = PaymentMethodData(
  type: PaymentMethodType.walletBalance,
  title: 'Wallet balance',
  subtitle: 'Pay from your BMT balance',
);

const _card = PaymentMethodData(
  type: PaymentMethodType.creditCard,
  title: 'Card',
  subtitle: 'Visa or Mastercard',
  recommended: true,
);

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

void main() {
  group('CheckoutPromoField', () {
    testWidgets('stays folded away until the rider asks for it', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          CheckoutPromoField(
            controller: controller,
            status: PromoStatus.none,
            code: null,
            discount: 0,
            onApply: () {},
            onClear: () {},
          ),
        ),
      );

      expect(find.text('Have a promo code?'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Have a promo code?'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('names a rejected code without claiming a discount', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'NOPE');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          CheckoutPromoField(
            controller: controller,
            status: PromoStatus.invalid,
            code: 'NOPE',
            discount: 0,
            onApply: () {},
            onClear: () {},
          ),
        ),
      );

      expect(find.text('That code is not valid'), findsOneWidget);
      expect(find.textContaining('applied'), findsNothing);
    });

    testWidgets('shows what an accepted code saved', (tester) async {
      final controller = TextEditingController(text: 'WELCOME10');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          CheckoutPromoField(
            controller: controller,
            status: PromoStatus.applied,
            code: 'WELCOME10',
            discount: 25,
            onApply: () {},
            onClear: () {},
          ),
        ),
      );

      expect(find.text('WELCOME10 applied — you save EGP 25'), findsOneWidget);
    });
  });

  group('CheckoutMethodPicker', () {
    testWidgets('says how short an underfunded wallet is', (tester) async {
      await tester.pumpWidget(
        _host(
          CheckoutMethodPicker(
            methods: const [_card, _wallet],
            selected: PaymentMethodType.creditCard,
            walletBalance: 60,
            total: 100,
            onSelect: (_) {},
          ),
        ),
      );

      expect(find.text('Balance EGP 60'), findsOneWidget);
      expect(
        find.textContaining('Short by EGP 40'),
        findsOneWidget,
        reason: 'an unusable wallet must say why, not just fail on tap',
      );
    });

    testWidgets('only the chosen method explains what happens next', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CheckoutMethodPicker(
            methods: const [_card, _wallet],
            selected: PaymentMethodType.creditCard,
            walletBalance: 500,
            total: 100,
            onSelect: (_) {},
          ),
        ),
      );

      expect(find.textContaining('Paymob'), findsOneWidget);
      expect(find.textContaining('Deducted from your balance'), findsNothing);
    });
  });

  group('CheckoutPayBar', () {
    testWidgets('disables the button and names the blocker', (tester) async {
      await tester.pumpWidget(
        _host(
          const CheckoutPayBar(
            total: 100,
            subtotal: 100,
            label: 'Pay now',
            onPay: null,
            blockedReason: 'Choose a payment method to continue.',
          ),
        ),
      );

      expect(find.text('Choose a payment method to continue.'), findsOneWidget);
      expect(find.text('EGP 100'), findsOneWidget);
    });

    testWidgets('strikes through the pre-discount total', (tester) async {
      await tester.pumpWidget(
        _host(
          CheckoutPayBar(
            total: 75,
            subtotal: 100,
            label: 'Pay now',
            onPay: () {},
          ),
        ),
      );

      expect(find.text('EGP 75'), findsOneWidget);
      expect(find.text('EGP 100'), findsOneWidget);
    });
  });
}
