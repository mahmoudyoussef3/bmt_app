import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/payment_checkout_screen.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_notice.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_pay_bar.dart';

import 'payment_fakes.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

Future<void> _pumpCheckout(
  WidgetTester tester, {
  FakePaymentRepository? repository,
  PaymentCheckoutData data = sampleCheckout,
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
      home: BlocProvider(
        create: (_) => cubitFor(repository ?? FakePaymentRepository()),
        child: PaymentCheckoutScreen(checkoutData: data),
      ),
    ),
  );
}

bool _payEnabled(WidgetTester tester) {
  final bar = tester.widget<CheckoutPayBar>(find.byType(CheckoutPayBar));
  return bar.onPay != null;
}

void main() {
  testWidgets('shows the checkout shape while methods load', (tester) async {
    await _pumpCheckout(tester);

    // Before the cubit settles: a skeleton of the screen that is coming, not a
    // blank page or a bare spinner.
    expect(find.byType(ClientSkeleton), findsWidgets);
    expect(find.text('Checkout'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(ClientSkeleton), findsNothing);
  });

  testWidgets('renders raw trip clocks as readable times', (tester) async {
    await _pumpCheckout(tester);
    await tester.pumpAndSettle();

    expect(find.text('8:30 AM'), findsOneWidget);
    expect(find.text('11:45 AM'), findsOneWidget);
    expect(find.text('3h 15m'), findsOneWidget);
    expect(
      find.textContaining('08:30:00'),
      findsNothing,
      reason: 'the rider should never see a database clock',
    );
  });

  testWidgets('totals the fare and offers to pay it', (tester) async {
    await _pumpCheckout(tester);
    await tester.pumpAndSettle();

    // 100 fare + 10 service fee, shown on the fare card and the pay bar.
    expect(find.text('EGP 110'), findsNWidgets(2));
    expect(find.text('Pay now'), findsOneWidget);
    expect(_payEnabled(tester), isTrue);
  });

  testWidgets('a transfer method continues to the receipt step instead', (
    tester,
  ) async {
    // The method tiles sit below the fold of a phone-sized checkout, and the
    // body is a lazy list — give it a surface tall enough to build them.
    await _pumpCheckout(tester, size: const Size(390, 1600));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('InstaPay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('InstaPay'));
    await tester.pumpAndSettle();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Pay now'), findsNothing);
  });

  testWidgets('an underfunded wallet blocks payment and says why', (
    tester,
  ) async {
    // The method tiles sit below the fold of a phone-sized checkout, and the
    // body is a lazy list — give it a surface tall enough to build them.
    await _pumpCheckout(tester, size: const Size(390, 1600));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Wallet balance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wallet balance'));
    await tester.pumpAndSettle();

    // Balance is 40, fare is 110.
    expect(find.textContaining('EGP 70 short'), findsOneWidget);
    expect(
      _payEnabled(tester),
      isFalse,
      reason: 'the rider must not be able to press pay into a known failure',
    );
  });

  testWidgets('an incomplete booking is named, not silently accepted', (
    tester,
  ) async {
    await _pumpCheckout(
      tester,
      data: const PaymentCheckoutData(
        tripId: 'trip-1',
        pickupPoint: 'Nasr City',
        destination: 'Alexandria',
        vehicleNumber: '',
        tripDate: '2030-01-01',
        departureTime: '08:30:00',
        arrivalTime: '11:45:00',
        selectedSeatId: '',
        selectedSeat: '',
        driverName: 'Ahmed Samir',
        baseFare: 100,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutNotice), findsOneWidget);
    expect(find.textContaining('missing'), findsWidgets);
    expect(_payEnabled(tester), isFalse);
  });

  testWidgets('a failed load offers a retry rather than an empty screen', (
    tester,
  ) async {
    await _pumpCheckout(
      tester,
      repository: FakePaymentRepository(methodsThrow: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(CheckoutPayBar), findsNothing);
  });

  testWidgets('applies a promo code to the total', (tester) async {
    await _pumpCheckout(
      tester,
      repository: FakePaymentRepository(discounts: const {'WELCOME10': 30}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Have a promo code?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'welcome10');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME10 applied — you save EGP 30'), findsOneWidget);
    expect(find.text('EGP 80'), findsNWidgets(2)); // fare card + pay bar
    expect(find.text('EGP 110'), findsOneWidget); // struck through on the bar
  });

  testWidgets('lays out on a small phone without overflowing', (tester) async {
    await _pumpCheckout(tester, size: const Size(320, 640));
    await tester.pumpAndSettle();

    // Scroll the whole page past every card, so a card that only overflows once
    // it is laid out still reports.
    await tester.scrollUntilVisible(find.text('Wallet balance'), 120);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out in dark mode without overflowing', (tester) async {
    await _pumpCheckout(tester, brightness: Brightness.dark);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
