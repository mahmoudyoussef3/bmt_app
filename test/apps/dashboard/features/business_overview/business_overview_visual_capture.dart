/// Visual QA harness for نظرة تنفيذية — the console's executive tab.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/business_overview/business_overview_visual_capture.dart --update-goldens
///
/// Typesets with the **real** [DashboardAppTheme] by registering a host Arabic
/// face under the family names google_fonts asks for (`Cairo_regular`, falling
/// back to `Cairo`). Without that the binding draws every glyph as a box and
/// the capture judges nothing but layout. Material icons still render as boxes;
/// what these prove is spacing, hierarchy, contrast, dark mode and RTL.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_overview.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/cubit/business_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/cubit/business_overview_state.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/models/overview_window.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/screens/business_overview_screen.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    as finance;
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_money_model.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

import 'business_overview_test_fixtures.dart';

class _StaticCubit extends Cubit<BusinessOverviewState>
    implements BusinessOverviewCubit {
  _StaticCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}
}

const _office = OfficeContext(
  officeId: 'office-1',
  officeName: 'مكتب الميجا للنقل',
  officeSlug: 'mega-transport',
  role: DashboardRole.admin,
  username: 'owner',
  fullName: 'محمود يوسف',
  listingStatus: 'listed',
);

/// A trading office with 45 days of history — enough for the 30-day window to
/// have a full baseline behind it, so the trend chips are real rather than
/// suppressed.
BusinessOverview _busyOffice({Set<BusinessDataSource> unavailable = const {}}) {
  final random = Random(7);
  const routes = [
    'بنها - القاهرة',
    'طنطا - الإسكندرية',
    'أسيوط - القاهرة',
    'المنصورة - القاهرة',
  ];

  final trips = <OperationTrip>[];
  final bookings = <OperationBooking>[];

  for (var day = 60; day >= 0; day--) {
    final at = daysAgo(day);
    final tripsToday = 2 + random.nextInt(3);
    for (var i = 0; i < tripsToday; i++) {
      final route = routes[(day + i) % routes.length];
      final capacity = 14;
      // Later days run fuller, so the period trend has somewhere to go.
      final fill = (0.40 + (60 - day) / 130 + random.nextDouble() * 0.22).clamp(
        0.2,
        1.0,
      );
      final booked = (capacity * fill).round();
      trips.add(
        buildTrip(
          id: 'trip-$day-$i',
          route: route,
          capacity: capacity,
          bookedSeats: booked,
          driverId: 'driver-${i % 5}',
          vehicleId: 'vehicle-${i % 4}',
          at: DateTime(at.year, at.month, at.day, 7 + i * 4),
          status: day == 0
              ? (i == 0
                    ? OperationTripStatus.completed
                    : i == 1
                    ? OperationTripStatus.inProgress
                    : OperationTripStatus.scheduled)
              : OperationTripStatus.completed,
        ),
      );

      for (var seat = 0; seat < booked; seat++) {
        final unpaid = random.nextDouble() < 0.12;
        bookings.add(
          buildBooking(
            id: 'bk-$day-$i-$seat',
            clientId: 'client-${random.nextInt(140)}',
            amount: 85 + random.nextInt(6) * 15,
            createdAt: DateTime(at.year, at.month, at.day, 8 + seat % 10),
            paymentStatus: unpaid
                ? PaymentStatus.submitted
                : PaymentStatus.approved,
            status: random.nextDouble() < 0.06
                ? BookingStatus.cancelled
                : BookingStatus.reserved,
          ),
        );
      }
    }
  }

  return buildOverview(
    trips: trips,
    bookings: bookings,
    fleet: buildFleet(
      activeDrivers: 9,
      activeVehicles: 6,
      vehiclesInMaintenance: 2,
    ),
    reviews: [
      for (var i = 0; i < 34; i++)
        buildReview(
          id: 'rev-$i',
          rating: 3 + (i % 3),
          createdAt: daysAgo(i % 40),
        ),
    ],
    refundRequests: [
      buildRefund(id: 'rf-1', amount: 180),
      buildRefund(id: 'rf-2', amount: 95),
      buildRefund(
        id: 'rf-3',
        amount: 240,
        status: finance.RefundStatus.approved,
        date: daysAgo(4),
      ),
    ],
    captainRequests: [
      buildCaptainRequest(id: 'cr-1'),
      buildCaptainRequest(id: 'cr-2'),
    ],
    tickets: [
      buildTicket(id: 'tk-1', priority: TicketPriority.urgent),
      buildTicket(id: 'tk-2', priority: TicketPriority.urgent),
    ],
    wallet: buildWallet(
      liability: 14350,
      movements: [
        for (var day = 45; day >= 0; day--)
          WalletMovement(
            date: daysAgo(day),
            kind: day.isEven
                ? WalletMovementKind.cashback
                : WalletMovementKind.walletSpend,
            amount: day.isEven ? 120.0 : -90.0,
          ),
      ],
      refunds: [
        SettledRefund(settledAt: daysAgo(4), amount: 240, toWallet: true),
        SettledRefund(settledAt: daysAgo(11), amount: 310, toWallet: false),
      ],
    ),
    unavailable: unavailable,
  );
}

void main() {
  late ThemeData light;
  late ThemeData dark;

  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final bytes = ByteData.sublistView(file.readAsBytesSync());
      for (final family in const ['Cairo_regular', 'Cairo']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }
    // google_fonts' fetch fails under the test binding and swallows its own
    // failure; the zone keeps the complaint off whichever test is running.
    await runZonedGuarded(() async {
      light = DashboardAppTheme.light();
      dark = DashboardAppTheme.dark();
    }, (_, _) {});
  });

  setUp(DashboardSectionStateStore.instance.clear);

  testWidgets('console width, 30 days — light', (tester) async {
    await _capture(
      tester,
      'business_overview_1_console_light',
      theme: light,
      overview: _busyOffice(),
    );
  });

  testWidgets('console width, 30 days — dark', (tester) async {
    await _capture(
      tester,
      'business_overview_2_console_dark',
      theme: dark,
      overview: _busyOffice(),
    );
  });

  testWidgets('7-day window on a smaller console', (tester) async {
    await _capture(
      tester,
      'business_overview_3_week_light',
      theme: light,
      overview: _busyOffice(),
      window: OverviewWindow.week,
      width: 1280,
    );
  });

  testWidgets('narrow window — the two columns interleave', (tester) async {
    await _capture(
      tester,
      'business_overview_4_narrow_light',
      theme: light,
      overview: _busyOffice(),
      width: 820,
      height: 4200,
    );
  });

  testWidgets('a quiet office with feeds missing', (tester) async {
    await _capture(
      tester,
      'business_overview_5_degraded_light',
      theme: light,
      overview: buildOverview(
        unavailable: {BusinessDataSource.wallet, BusinessDataSource.reviews},
      ),
      height: 2400,
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required ThemeData theme,
  required BusinessOverview overview,
  OverviewWindow window = OverviewWindow.month,
  double width = 1600,
  double height = 3000,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = _StaticCubit(BusinessOverviewLoaded(overview));
  addTearDown(cubit.close);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: BlocProvider<BusinessOverviewCubit>.value(
              value: cubit,
              child: BusinessOverviewScreen(
                office: _office,
                canOpenRoute: (_) => true,
                onOpenModule: (_) {},
                onCreateTrip: () {},
                initialWindow: window,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}
