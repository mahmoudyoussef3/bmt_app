/// Visual QA harness for العملاء — the directory and the Customer 360
/// workspace, in both themes.
///
/// This module is dense: seven columns of mixed Arabic and latin, three status
/// axes on one trip row, a usage bar that is sometimes absent on purpose, and a
/// header whose chips are generated rather than authored. None of that can be
/// judged from code.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/customers/customers_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_activity.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_filters.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_payment.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_profile.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_trip.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customer_profile_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customer_profile_state.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customers_state.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/screens/customers_screen.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/widgets/customer_profile_view.dart';

import 'customers_test_fixtures.dart';

const _captureFont = 'CaptureArabic';

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  setUp(() {
    DashboardFilterMemory.instance.clear();
    DashboardSectionStateStore.instance.clear();
  });
  tearDown(() {
    DashboardFilterMemory.instance.clear();
    DashboardSectionStateStore.instance.clear();
  });

  group('directory', () {
    testWidgets('the table, dark', (tester) async {
      await _captureDirectory(tester, 'customers_1_directory_dark', dark: true);
    });

    testWidgets('the table, light', (tester) async {
      await _captureDirectory(
        tester,
        'customers_2_directory_light',
        dark: false,
      );
    });

    testWidgets('the card layout below the breakpoint', (tester) async {
      await _captureDirectory(
        tester,
        'customers_3_directory_cards_dark',
        dark: true,
        width: 900,
      );
    });

    testWidgets('nothing matched the search', (tester) async {
      await _captureDirectory(
        tester,
        'customers_4_directory_no_results_light',
        dark: false,
        height: 900,
        empty: true,
      );
    });
  });

  group('customer 360', () {
    for (final tab in CustomerProfileTab.values) {
      testWidgets('${tab.name}, dark', (tester) async {
        await _captureProfile(
          tester,
          'customers_5_${tab.name}_dark',
          dark: true,
          tab: tab,
        );
      });
    }

    testWidgets('overview, light', (tester) async {
      await _captureProfile(
        tester,
        'customers_6_overview_light',
        dark: false,
        tab: CustomerProfileTab.overview,
      );
    });

    testWidgets('a tab that failed while the rest still works', (tester) async {
      await _captureProfile(
        tester,
        'customers_7_partial_failure_dark',
        dark: true,
        tab: CustomerProfileTab.payments,
        paymentsStatus: const CustomerTabStatus(error: 'انقطع الاتصال بالخادم'),
      );
    });
  });
}

/// Twelve customers spanning every treatment the table can draw: with and
/// without a package, travelling soon or not, active and dormant, wallet and no
/// wallet, and one name long enough to test the identity column's truncation.
List<CustomerSummary> _seed() {
  const names = [
    'منى عبد الرحمن',
    'كريم الشاذلي',
    'سارة مجدي',
    'عبد الرحمن محمد فتحي الشناوي',
    'نورهان فتحي',
    'أيمن الجندي',
    'هبة سليمان',
    'رامي عز الدين',
  ];

  return List.generate(names.length, (i) {
    final hasPackage = i % 3 != 2;
    final rides = 6 + (i * 3) % 18;
    return summaryFixture(
      clientId: 'client-$i',
      fullName: names[i],
      phone: '0100000${(1000 + i)}',
      email: i.isEven ? 'passenger$i@example.com' : null,
      bookingsTotal: 4 + (i * 5) % 23,
      bookingsCompleted: 2 + (i * 3) % 15,
      bookingsCancelled: i % 4,
      lastActivityAt: i % 5 == 4
          ? testNow.subtract(Duration(days: 96 + i))
          : testNow.subtract(Duration(hours: 3 + i * 7)),
      nextTripDate: i % 4 == 0
          ? DateTime(testNow.year, testNow.month, testNow.day + 1 + i % 3)
          : null,
      activePackageName: hasPackage
          ? const [
              'أسبوع عمل (٥ أيام)',
              'أسبوعين عمل (١٠ أيام)',
              'ثلاثة أشهر',
            ][i % 3]
          : null,
      activePackageTripsCount: hasPackage ? rides : null,
      activePackageTripsUsed: hasPackage ? (i * 2) % rides : null,
      totalPaid: 640 + (i * 437) % 5200,
      walletBalance: i % 3 == 0 ? 45.0 + (i * 31) % 400 : null,
    );
  });
}

Future<void> _captureDirectory(
  WidgetTester tester,
  String name, {
  required bool dark,
  double width = 1500,
  double height = 1400,
  bool empty = false,
}) async {
  final rows = empty ? <CustomerSummary>[] : _seed();
  final state = CustomersLoadedState(
    overview: overviewFixture(
      totalCustomers: 148,
      activeCustomers: 61,
      withActiveSubscription: 34,
      withUpcomingTrip: 12,
      newCustomers: 9,
    ),
    page: CustomerDirectoryPage(total: empty ? 0 : 148, rows: rows),
    // The empty capture is the *search* empty state, which is a different
    // message from "this office has no customers yet".
    filters: empty
        ? const CustomerFilters(search: 'زياد')
        : const CustomerFilters(),
  );

  await _pump(
    tester,
    name,
    dark: dark,
    width: width,
    height: height,
    child: BlocProvider<CustomersCubit>.value(
      value: _StaticDirectoryCubit(state),
      child: const CustomersScreen(),
    ),
  );
}

Future<void> _captureProfile(
  WidgetTester tester,
  String name, {
  required bool dark,
  required CustomerProfileTab tab,
  double width = 1500,
  double height = 1500,
  CustomerTabStatus? paymentsStatus,
}) async {
  final state = CustomerProfileLoadedState(
    profile: profileFixture(
      fullName: 'منى عبد الرحمن',
      metrics: metricsFixture(
        bookingsTotal: 27,
        bookingsUpcoming: 2,
        bookingsCompleted: 21,
        bookingsCancelled: 3,
        boardedCount: 19,
        noShowCount: 2,
        totalPaid: 6420,
        paymentsCount: 24,
        subscriptionsTotal: 3,
        activeSubscriptions: 1,
        walletBalance: 168,
        reviewsCount: 5,
        avgOfficeRating: 4.6,
        ticketsTotal: 2,
        nextTripDate: DateTime(testNow.year, testNow.month, testNow.day + 1),
      ),
      activeSubscription: subscriptionFixture(
        packageName: 'أسبوعين عمل (١٠ أيام)',
        tripsCount: 20,
        tripsUsed: 7,
        usagePercent: 35,
      ),
      topRoutes: const [
        CustomerRoute(route: 'القاهرة → الإسكندرية', trips: 12),
        CustomerRoute(route: 'المنصورة → القاهرة', trips: 7),
        CustomerRoute(route: 'طنطا → الإسكندرية', trips: 3),
      ],
    ),
    tab: tab,
    showPastTrips: true,
    pastTrips: CustomerTripsPage(
      total: 21,
      rows: [
        tripFixture(bookingId: 'b1', subscriptionName: 'أسبوعين عمل (١٠ أيام)'),
        tripFixture(bookingId: 'b2', boardingStatus: 'no_show'),
        tripFixture(
          bookingId: 'b3',
          status: 'cancelled',
          paymentStatus: 'refunded',
          boardingStatus: null,
        ),
        tripFixture(bookingId: 'b4', boardingStatus: 'reserved'),
      ],
    ),
    tripsStatus: const CustomerTabStatus(loaded: true),
    subscriptions: [
      subscriptionFixture(id: 's1', usagePercent: 35, tripsUsed: 7),
      subscriptionFixture(
        id: 's2',
        packageName: 'أسبوع عمل (٥ أيام)',
        status: 'expired',
        tripsCount: 10,
        tripsUsed: 10,
        usagePercent: 100,
        isCurrent: false,
      ),
      // The row that must say why it has no percentage.
      subscriptionFixture(
        id: 's3',
        packageName: 'اشتراك مفتوح',
        status: 'cancelled',
        tripsCount: 0,
        tripsUsed: 0,
        usagePercent: null,
        isCurrent: false,
      ),
    ],
    subscriptionsStatus: const CustomerTabStatus(loaded: true),
    payments: CustomerPaymentsPage(
      total: 24,
      totalApproved: 6420,
      rows: [
        paymentFixture(id: 'p1'),
        paymentFixture(id: 'p2', status: 'submitted', amount: 280),
        paymentFixture(id: 'p3', amount: 95),
      ],
      wallet: const CustomerWallet(
        balance: 168,
        availableBalance: 168,
        reservedBalance: 0,
        currency: 'EGP',
        status: 'active',
        lifetimeCredited: 640,
        lifetimeDebited: 472,
      ),
      walletTransactions: [
        CustomerWalletEntry(
          id: 'w1',
          kind: 'refund',
          category: 'trip_cancelled',
          amount: 180,
          currency: 'EGP',
          balanceAfter: 168,
          reason: 'استرداد رحلة ملغاة',
          createdAt: testNow.subtract(const Duration(days: 6)),
          performedByName: 'محمود يوسف',
        ),
        CustomerWalletEntry(
          id: 'w2',
          kind: 'manual_debit',
          category: 'correction',
          amount: 60,
          currency: 'EGP',
          balanceAfter: 348,
          reason: 'تسوية فرق تذكرة',
          createdAt: testNow.subtract(const Duration(days: 11)),
          performedByName: 'محمود يوسف',
        ),
      ],
    ),
    paymentsStatus: paymentsStatus ?? const CustomerTabStatus(loaded: true),
    activity: [
      activityFixture(at: testNow.subtract(const Duration(hours: 2))),
      activityFixture(
        kind: CustomerActivityKind.paymentApproved,
        at: testNow.subtract(const Duration(hours: 3)),
        amount: 180,
      ),
      activityFixture(
        kind: CustomerActivityKind.boarded,
        at: testNow.subtract(const Duration(days: 1, hours: 4)),
      ),
      activityFixture(
        kind: CustomerActivityKind.subscriptionCreated,
        at: testNow.subtract(const Duration(days: 5)),
        amount: 1580,
      ),
      activityFixture(
        kind: CustomerActivityKind.noShow,
        at: testNow.subtract(const Duration(days: 11)),
      ),
    ],
    activityStatus: const CustomerTabStatus(loaded: true),
  );

  await _pump(
    tester,
    name,
    dark: dark,
    width: width,
    height: height,
    child: BlocProvider<CustomerProfileCubit>.value(
      value: _StaticProfileCubit(state),
      child: CustomerProfileView(fallbackName: 'منى عبد الرحمن', onBack: () {}),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  String name, {
  required bool dark,
  required double width,
  required double height,
  required Widget child,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeWithHostFont(dark: dark),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// See the note in the bookings harness: the real themes build their text theme
/// through google_fonts, which the test binding's blocked network turns into a
/// post-test throw. The palette is the real one; only the glyphs differ.
ThemeData _themeWithHostFont({required bool dark}) {
  final scheme = dark
      ? darkColorSchemeFromPalette()
      : lightColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: dark
        ? AppDarkColors.background
        : AppLightColors.background,
    canvasColor: dark ? AppDarkColors.background : AppLightColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: dark ? AppDarkColors.shadow : AppLightColors.shadow,
    extensions: [AppSurfaceStyle.flat(scheme)],
  );
}

class _StaticDirectoryCubit extends Cubit<CustomersState>
    implements CustomersCubit {
  _StaticDirectoryCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StaticProfileCubit extends Cubit<CustomerProfileState>
    implements CustomerProfileCubit {
  _StaticProfileCubit(super.initialState);

  @override
  String get clientId => 'client-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
