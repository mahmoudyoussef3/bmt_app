import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/payment/wizard_receipt_upload.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/payment/wizard_transfer_panel.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_payment_step.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/get_payment_methods_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_method_tile.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_pay_bar.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_ticket_card.dart';

import '../../payments/payment_fakes.dart';

const _route = RouteOptionData(
  id: 'r1',
  routeName: 'Nasr City → Alexandria',
  pickup: 'Nasr City',
  destination: 'Alexandria',
  distance: '220 km',
  duration: '3h 15m',
  availableSeats: 12,
  startingPrice: 'EGP 40',
  priceRange: 'EGP 40',
  availableTrips: [],
);

BookingWizardCubit _sessionCubit() {
  return BookingWizardCubit(_route)
    ..selectPickup(const RoutePointData(id: 'p1', name: 'Nasr City', order: 1))
    ..selectDropoff(
      const RoutePointData(id: 'p2', name: 'Alexandria', order: 4),
    )
    ..selectTrip(
      const RouteTripOptionData(
        id: 't1',
        tripDate: '2030-01-08',
        departureTime: '08:30:00',
        arrivalTime: '11:45:00',
        availableSeats: 9,
        vehicleType: 'BUS-114',
        price: 'EGP 40',
      ),
    )
    ..selectSeat('s1', 'D2');
}

Future<BookingWizardCubit> _pumpStep(
  WidgetTester tester, {
  FakePaymentRepository? repository,
  Size view = const Size(400, 1800),
}) async {
  // Tall enough that the whole checkout is laid out at once: the list is lazy,
  // and a rider on a real phone reaches the same widgets by scrolling.
  tester.view.physicalSize = view;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  clientGetIt.registerSingleton<GetPaymentMethodsUseCase>(
    GetPaymentMethodsUseCase(repository ?? FakePaymentRepository()),
  );
  addTearDown(clientGetIt.reset);

  final cubit = _sessionCubit();
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider<BookingWizardCubit>.value(
          value: cubit,
          child: WizardPaymentStep(onConfirm: () {}, onFix: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  testWidgets('pays on the shared checkout, not a wizard-only screen', (
    tester,
  ) async {
    await _pumpStep(tester);

    expect(find.byType(CheckoutTicketCard), findsOneWidget);
    expect(find.byType(CheckoutPayBar), findsOneWidget);
    expect(find.text('Fare summary'), findsOneWidget);
    expect(find.text('How would you like to pay?'), findsOneWidget);
  });

  testWidgets('hides the wallet, which the booking RPCs cannot settle', (
    tester,
  ) async {
    await _pumpStep(tester);

    expect(find.byType(CheckoutMethodTile), findsNWidgets(2));
    expect(find.text('Wallet balance'), findsNothing);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('InstaPay'), findsOneWidget);
  });

  testWidgets('will not let a rider pay before choosing a method', (
    tester,
  ) async {
    await _pumpStep(tester);

    expect(find.text('Choose a payment method to continue.'), findsOneWidget);
    final bar = tester.widget<CheckoutPayBar>(find.byType(CheckoutPayBar));
    expect(bar.onPay, isNull);
  });

  testWidgets('a card unblocks the bar; a transfer waits for its receipt', (
    tester,
  ) async {
    final cubit = await _pumpStep(tester);

    cubit.selectPaymentMethod('credit_card');
    await tester.pumpAndSettle();
    var bar = tester.widget<CheckoutPayBar>(find.byType(CheckoutPayBar));
    expect(bar.blockedReason, isNull);
    expect(bar.onPay, isNotNull);
    expect(bar.label, 'Pay now');
    expect(find.byType(WizardReceiptUpload), findsNothing);

    cubit.selectPaymentMethod('instapay');
    await tester.pumpAndSettle();
    bar = tester.widget<CheckoutPayBar>(find.byType(CheckoutPayBar));
    expect(bar.label, 'Submit receipt');
    expect(bar.onPay, isNull);
    expect(
      find.text('Attach your transfer receipt to continue.'),
      findsOneWidget,
    );
    expect(find.byType(WizardTransferPanel), findsOneWidget);

    cubit.setReceiptUrl('https://receipts/1.png');
    await tester.pumpAndSettle();
    bar = tester.widget<CheckoutPayBar>(find.byType(CheckoutPayBar));
    expect(bar.blockedReason, isNull);
    expect(bar.onPay, isNotNull);
  });

  testWidgets('offers a retry when the payment methods cannot be loaded', (
    tester,
  ) async {
    await _pumpStep(
      tester,
      repository: FakePaymentRepository(methodsThrow: true),
    );

    expect(
      find.textContaining('could not load the ways to pay'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(CheckoutPayBar), findsNothing);
  });

  testWidgets('lays out on a small phone without overflowing', (tester) async {
    final cubit = await _pumpStep(tester, view: const Size(360, 640));

    cubit.selectPaymentMethod('instapay');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
