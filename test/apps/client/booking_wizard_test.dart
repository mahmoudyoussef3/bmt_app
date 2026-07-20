import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_step_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/booking_wizard_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/wizard_booking_params.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_progress_bar.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_stop_step.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/domain/repositories/payment_repository.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/await_card_settlement_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/create_card_payment_session_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/get_payment_methods_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/start_card_checkout_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/entities/seat_option.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/repositories/seat_selection_repository.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/confirm_seat_booking_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/lock_trip_seat_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/place_seat_booking_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/release_trip_seat_lock_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/update_existing_booking_payment_usecase.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

class _FakeSeatRepository implements SeatSelectionRepository {
  _FakeSeatRepository({this.confirmError, this.confirmResult});

  final Object? confirmError;

  /// Lets a test hold the confirm open and inspect the wizard mid-flight.
  final Future<Map<String, dynamic>>? confirmResult;
  final List<String> calls = [];
  Map<String, dynamic>? confirmParams;

  @override
  Future<Map<String, dynamic>> lockTripSeat({
    required String tripId,
    required String seatId,
  }) async {
    calls.add('lock');
    return {'seat_id': seatId};
  }

  @override
  Future<void> releaseTripSeatLock({
    required String tripId,
    required String seatId,
  }) async {
    calls.add('release');
  }

  @override
  Future<Map<String, dynamic>> confirmSeatBooking(
    Map<String, dynamic> params,
  ) async {
    calls.add('confirm');
    confirmParams = params;
    final error = confirmError;
    if (error != null) throw error;
    final pending = confirmResult;
    if (pending != null) return pending;
    return {'booking_id': 'b-1234567890', 'booking_number': 'BMT-77'};
  }

  @override
  Future<Map<String, dynamic>> updateExistingBookingPayment(
    Map<String, dynamic> params,
  ) async {
    calls.add('update');
    return {'booking_id': 'b-1234567890', 'booking_number': 'BMT-77'};
  }

  @override
  Future<SeatSelectionData> getSeatSelectionData(String tripId) =>
      throw UnimplementedError();

  @override
  @Deprecated('Use lockTripSeat + confirmSeatBooking instead')
  Future<String> bookTripSeat(Map<String, dynamic> params) =>
      throw UnimplementedError();
}

const _cardMethod = PaymentMethodData(
  type: PaymentMethodType.creditCard,
  title: 'Card',
  subtitle: 'Visa / Mastercard',
);

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository({
    this.methods = const [],
    this.settlement = const CardPaymentState(
      settled: false,
      failed: false,
      bookingStatus: 'reserved',
      paymentStatus: 'pending',
    ),
  });

  final List<PaymentMethodData> methods;

  /// What the backend says the gateway settled on — the only thing the cubit
  /// is allowed to believe about whether money moved.
  final CardPaymentState settlement;

  @override
  Future<List<PaymentMethodData>> getPaymentMethods() async => methods;

  @override
  Future<CardPaymentState> getCardPaymentState(String bookingId) async =>
      settlement;

  @override
  Future<CardPaymentSession> createCardPaymentSession({
    required PaymentCheckoutData checkoutData,
    required PaymentMethodData paymentMethod,
    required String bookingId,
    required int amount,
  }) async => const CardPaymentSession(
    checkoutUrl: 'https://pay.test/checkout',
    gatewayReference: 'g-1',
  );

  @override
  Future<int> validatePromoCode(String code) => throw UnimplementedError();

  @override
  Future<String> uploadReceipt({
    required String bookingOrTripId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) => throw UnimplementedError();
}

BookingWizardConfirmCubit _cubit({
  required _FakeSeatRepository seats,
  _FakePaymentRepository? payments,
}) {
  final paymentRepository = payments ?? _FakePaymentRepository();
  return BookingWizardConfirmCubit(
    placeSeatBooking: PlaceSeatBookingUseCase(
      lockTripSeat: LockTripSeatUseCase(seats),
      confirmSeatBooking: ConfirmSeatBookingUseCase(seats),
      releaseTripSeatLock: ReleaseTripSeatLockUseCase(seats),
    ),
    updateExistingBookingPayment: UpdateExistingBookingPaymentUseCase(seats),
    // A real 20-second wait proves nothing a 60-millisecond one does not.
    awaitCardSettlement: AwaitCardSettlementUseCase(
      paymentRepository,
      pollTimeout: const Duration(milliseconds: 60),
      pollInterval: const Duration(milliseconds: 10),
    ),
    startCardCheckout: StartCardCheckoutUseCase(
      getPaymentMethods: GetPaymentMethodsUseCase(paymentRepository),
      createCardPaymentSession: CreateCardPaymentSessionUseCase(
        paymentRepository,
      ),
    ),
  );
}

const _route = RouteOptionData(
  id: 'r-1',
  routeName: 'Cairo → Alexandria',
  pickup: 'Cairo',
  destination: 'Alexandria',
  distance: '220 km',
  duration: '3h',
  availableSeats: 12,
  startingPrice: 'EGP 120',
  priceRange: 'EGP 120',
  availableTrips: [],
);

BookingWizardSession _session({
  String paymentMethod = 'instapay',
  String? bookingId,
}) => BookingWizardSession(
  route: _route,
  pickupStop: const RoutePointData(id: 'p-1', name: 'Cairo', order: 0),
  dropoffStop: const RoutePointData(id: 'p-2', name: 'Alexandria', order: 3),
  selectedTrip: const RouteTripOptionData(
    id: 't-1',
    departureTime: '08:00',
    arrivalTime: '11:00',
    availableSeats: 10,
    vehicleType: 'Hiace',
    price: 'EGP 120',
    tripDate: '2026-08-01',
  ),
  selectedSeatId: 's-1',
  selectedSeatLabel: 'A1',
  paymentMethod: paymentMethod,
  receiptUrl: 'https://files.test/receipt.png',
  bookingId: bookingId,
);

/// Pumps the wizard with the three cubits its route scope provides.
Future<BookingWizardStepCubit> _pumpWizard(
  WidgetTester tester, {
  BookingWizardConfirmCubit? confirmCubit,
}) async {
  final steps = BookingWizardStepCubit();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<BookingWizardCubit>(
            create: (_) => BookingWizardCubit(_route),
          ),
          BlocProvider<BookingWizardStepCubit>.value(value: steps),
          BlocProvider<BookingWizardConfirmCubit>.value(
            value: confirmCubit ?? _cubit(seats: _FakeSeatRepository()),
          ),
        ],
        child: const BookingWizardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return steps;
}

void main() {
  group('BookingWizardStepCubit', () {
    test('walks forward and stops at the last step', () {
      final cubit = BookingWizardStepCubit();
      for (var i = 0; i < BookingWizardStepCubit.stepCount + 2; i++) {
        cubit.next();
      }
      expect(cubit.state, BookingWizardStepCubit.stepCount - 1);
    });

    test('back reports the first step so the route can pop instead', () {
      final cubit = BookingWizardStepCubit();
      cubit.next();
      expect(cubit.back(), isTrue);
      expect(cubit.state, 0);
      expect(cubit.back(), isFalse);
    });

    test('editStep ignores steps outside the wizard', () {
      final cubit = BookingWizardStepCubit()..editStep(4);
      expect(cubit.state, 4);
      cubit.editStep(BookingWizardStepCubit.stepCount);
      cubit.editStep(-1);
      expect(cubit.state, 4);
    });
  });

  group('BookingWizardConfirmCubit', () {
    test('locks then confirms, and reports a storable new booking', () async {
      final seats = _FakeSeatRepository();
      final cubit = _cubit(seats: seats);

      await cubit.confirm(_session());

      expect(seats.calls, ['lock', 'confirm']);
      final state = cubit.state as BookingWizardConfirmed;
      expect(state.record.id, 'b-1234567890');
      expect(state.record.reference, 'BMT-77');
      expect(state.record.isStorable, isTrue);
      // A receipt method is settled by an operator, not the gateway.
      expect(state.requiresVerification, isTrue);
    });

    test('hands the seat lock back when the confirm fails', () async {
      final seats = _FakeSeatRepository(
        confirmError: Exception('seat_unavailable'),
      );
      final cubit = _cubit(seats: seats);

      await cubit.confirm(_session());

      expect(seats.calls, ['lock', 'confirm', 'release']);
      expect(
        (cubit.state as BookingWizardConfirmFailed).reason,
        'seat_unavailable',
      );
    });

    test(
      'a session with a booking id settles it instead of booking again',
      () async {
        final seats = _FakeSeatRepository();
        final cubit = _cubit(seats: seats);

        await cubit.confirm(_session(bookingId: 'b-1234567890'));

        expect(seats.calls, ['update']);
        expect(
          (cubit.state as BookingWizardConfirmed).record.isStorable,
          isFalse,
        );
      },
    );

    test('a card booking stops at the gateway and resumes when paid', () async {
      final seats = _FakeSeatRepository();
      final cubit = _cubit(
        seats: seats,
        payments: _FakePaymentRepository(
          methods: const [_cardMethod],
          // The gateway's signed callback has landed and settled the booking.
          settlement: const CardPaymentState(
            settled: true,
            failed: false,
            bookingStatus: 'confirmed',
            paymentStatus: 'approved',
          ),
        ),
      );

      await cubit.confirm(_session(paymentMethod: 'credit_card'));

      final checkout = cubit.state as BookingWizardCardCheckout;
      expect(checkout.checkoutUrl, 'https://pay.test/checkout');
      expect(checkout.record.reference, 'BMT-77');

      await cubit.cardPaymentFinished(true);
      final done = cubit.state as BookingWizardConfirmed;
      expect(done.requiresVerification, isFalse);
      expect(done.record.reference, 'BMT-77');
    });

    test('a card the gateway declined is reported as declined', () async {
      final cubit = _cubit(
        seats: _FakeSeatRepository(),
        payments: _FakePaymentRepository(
          methods: const [_cardMethod],
          settlement: const CardPaymentState(
            settled: false,
            failed: true,
            bookingStatus: 'reserved',
            paymentStatus: 'failed',
          ),
        ),
      );

      await cubit.confirm(_session(paymentMethod: 'credit_card'));
      await cubit.cardPaymentFinished(true);

      expect(
        (cubit.state as BookingWizardConfirmFailed).reason,
        'card_payment_declined',
      );
    });

    test(
      'a success redirect the backend has not settled yet is held for '
      'verification, never reported as paid or as failed',
      () async {
        final cubit = _cubit(
          seats: _FakeSeatRepository(),
          payments: _FakePaymentRepository(methods: const [_cardMethod]),
        );

        await cubit.confirm(_session(paymentMethod: 'credit_card'));
        await cubit.cardPaymentFinished(true);

        // The rider may well have been charged — Paymob's callback is simply
        // late. Calling that a failure would cost them the seat they paid for.
        final done = cubit.state as BookingWizardConfirmed;
        expect(done.requiresVerification, isTrue);
      },
    );

    test(
      'an abandoned card payment keeps the booking and explains why',
      () async {
        final seats = _FakeSeatRepository();
        final cubit = _cubit(
          seats: seats,
          payments: _FakePaymentRepository(methods: const [_cardMethod]),
        );

        await cubit.confirm(_session(paymentMethod: 'credit_card'));
        await cubit.cardPaymentFinished(false);

        expect(
          (cubit.state as BookingWizardConfirmFailed).reason,
          'card_payment_not_completed',
        );
        // The seat keeps its hold: the booking row already exists.
        expect(seats.calls, ['lock', 'confirm']);
      },
    );

    test('a card booking with no card method configured is refused', () async {
      final seats = _FakeSeatRepository();
      final cubit = _cubit(seats: seats);

      await cubit.confirm(_session(paymentMethod: 'credit_card'));

      expect(
        (cubit.state as BookingWizardConfirmFailed).reason,
        'card_payment_unavailable',
      );
    });

    test('an incomplete session never reaches the backend', () async {
      final seats = _FakeSeatRepository();
      final cubit = _cubit(seats: seats);

      await cubit.confirm(BookingWizardSession(route: _route));

      expect(seats.calls, isEmpty);
      expect(cubit.state, isA<BookingWizardConfirmIdle>());
    });
  });

  group('BookingWizardScreen', () {
    testWidgets('opens on the stops step, titled by the route', (tester) async {
      await _pumpWizard(tester);

      expect(find.text('Cairo → Alexandria'), findsOneWidget);
      expect(find.byType(WizardStopStep), findsOneWidget);
      expect(find.byType(WizardProgressBar), findsOneWidget);
    });

    testWidgets('the app bar walks back through the steps', (tester) async {
      final steps = await _pumpWizard(tester);
      steps.next();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(steps.state, 0);
      expect(find.byType(WizardStopStep), findsOneWidget);
    });

    testWidgets('a confirm in flight blocks the wizard', (tester) async {
      final pending = Completer<Map<String, dynamic>>();
      final seats = _FakeSeatRepository(confirmResult: pending.future);
      final confirm = _cubit(seats: seats);

      await _pumpWizard(tester, confirmCubit: confirm);
      unawaited(confirm.confirm(_session()));
      // Two frames: the cubit's state change reaches the builder on the next.
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final back = tester.widget<IconButton>(find.byType(IconButton).first);
      expect(back.onPressed, isNull);

      // The confirm is deliberately left hanging: what matters here is that the
      // wizard is sealed while it runs, not where it lands afterwards.
      addTearDown(() => pending.complete(const {}));
    });
  });

  group('wizardConfirmBookingParams', () {
    test('names the stops the rider picked and the fare they were shown', () {
      final params = wizardConfirmBookingParams(_session());

      expect(params['p_trip_id'], 't-1');
      expect(params['p_seat_id'], 's-1');
      expect(params['p_seat_label'], 'A1');
      expect(params['p_pickup_point_id'], 'p-1');
      expect(params['p_dropoff_point_id'], 'p-2');
      expect(params['p_route'], 'Cairo → Alexandria');
      expect(params['p_trip_date'], '2026-08-01');
      expect(params['p_payment_amount'], 120);
      expect(params['p_payment_method'], 'instapay');
    });

    test('a map-picked stop without an id is sent as null, not empty', () {
      final params = wizardConfirmBookingParams(
        BookingWizardSession(
          route: _route,
          pickupStop: const RoutePointData(name: 'Roadside', order: 0),
        ),
      );

      expect(params['p_pickup_point_id'], isNull);
    });

    test('the settle-payment call carries the booking it is settling', () {
      final params = wizardUpdatePaymentParams(_session(bookingId: 'b-9'));

      expect(params['p_booking_id'], 'b-9');
      expect(params['p_payment_method'], 'instapay');
      expect(params['p_receipt_url'], 'https://files.test/receipt.png');
    });
  });
}
