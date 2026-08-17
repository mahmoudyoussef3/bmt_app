import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_state.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/models/booking_filters.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    show FinanceLedger;

/// A capped list is only honest if the screen can tell it *was* capped. These
/// cover the two halves of that contract: the flag the state derives, and the
/// sentence the operator reads.

OperationBooking _booking(int index) => OperationBooking(
  id: 'booking-$index',
  bookingNumber: 'BK-$index',
  clientId: 'client-$index',
  passengerName: 'راكب $index',
  phone: '0100000000',
  route: 'القاهرة - الإسكندرية',
  tripTime: '08:00',
  date: '2026-08-16',
  seat: 'A$index',
  paymentMethod: BookingPaymentMethod.instaPay,
  status: BookingStatus.reserved,
  paymentStatus: PaymentStatus.submitted,
  paymentAmount: 100,
  packageName: 'pkg',
  createdAt: DateTime(2026, 8, 16),
  tripDetails: BookingTripDetails.empty,
  notes: const [],
  timeline: const [],
);

BookingsLoaded _loaded(int count) => BookingsLoaded(
  bookings: List.generate(count, _booking),
  filters: const BookingFilters(),
);

void main() {
  group('cap flag', () {
    test('a short list is not capped', () {
      expect(_loaded(10).capReached, isFalse);
    });

    test('a list one row short of the cap is not capped', () {
      expect(_loaded(DashboardQueryCaps.bookings - 1).capReached, isFalse);
    });

    test('a full page means the query hit its ceiling', () {
      expect(_loaded(DashboardQueryCaps.bookings).capReached, isTrue);
    });
  });

  group('cap notice', () {
    Widget wrap(Widget child) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: child)),
      ),
    );

    testWidgets('names the ceiling and what to do about it', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DashboardCapNotice(
            rowCap: DashboardQueryCaps.bookings,
            noun: 'حجز',
            hint: 'ضيّق الفلاتر للوصول لحجوزات أقدم.',
          ),
        ),
      );

      expect(
        find.text(
          'يعرض أحدث ${DashboardQueryCaps.bookings} حجز. '
          'ضيّق الفلاتر للوصول لحجوزات أقدم.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('offers no advice where narrowing would not help', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const DashboardCapNotice(
            rowCap: DashboardQueryCaps.reviews,
            noun: 'تقييم',
            hint: '',
          ),
        ),
      );

      expect(
        find.text('يعرض أحدث ${DashboardQueryCaps.reviews} تقييم'),
        findsOneWidget,
      );
    });

    testWidgets('survives a narrow window at 1.6x text scale', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: DashboardCapNotice(
                  rowCap: DashboardQueryCaps.bookings,
                  noun: 'حجز',
                  hint: 'ضيّق الفلاتر للوصول لحجوزات أقدم.',
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  test('finance keeps its own name for the shared ceiling', () {
    expect(FinanceLedger.rowCap, DashboardQueryCaps.financeLedger);
  });
}
