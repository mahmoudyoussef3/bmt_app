/// Visual QA harness for the redesigned subscriptions module — the full-width
/// subscriber board and the details sheet that replaced the permanent side
/// panel. Not a test of behaviour and deliberately not part of the suite's
/// assertions: run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/subscriptions/subscriptions_visual_capture.dart --update-goldens
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/data/datasources/subscriptions_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/subscription_trip.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/cancel_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/confirm_payment_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/create_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_creation_options_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_details_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_ride_usage_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscription_trips_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/mark_subscription_ride_used_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/renew_subscription_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/presentation/widgets/subscription_details_sheet.dart';

import 'subscriptions_test_fixtures.dart';

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

  testWidgets('the board, wide (3 columns)', (tester) async {
    await _capture(
      tester,
      'subscriptions_1_board_wide',
      width: 1900,
      height: 1500,
    );
  });

  testWidgets('the board, medium (2 columns)', (tester) async {
    await _capture(
      tester,
      'subscriptions_2_board_medium',
      width: 1200,
      height: 1600,
    );
  });

  testWidgets('the board, narrow (1 column)', (tester) async {
    await _capture(
      tester,
      'subscriptions_3_board_narrow',
      width: 700,
      height: 1900,
    );
  });

  testWidgets('subscriber details sheet', (tester) async {
    await _capture(
      tester,
      'subscriptions_4_details_sheet',
      width: 1900,
      height: 1500,
      openSheetFor: 'sub-1',
    );
  });
}

/// Ten subscribers so the wide board actually fills three columns and a couple
/// of rows — a single row would not show whether the grid squares cards off.
Datasource _seed() => Datasource(
  List.generate(10, (i) {
    final n = i + 1;
    return subscriptionFixture(
      id: 'sub-$n',
      status: n % 4 == 0
          ? SubscriptionStatus.pendingPayment
          : n % 7 == 0
          ? SubscriptionStatus.expired
          : SubscriptionStatus.active,
      userName: _names[i % _names.length],
      packageName: n % 2 == 0 ? 'باقة شهرية' : 'باقة أسبوعية',
      routeLabel: n % 3 == 0
          ? 'Al Marj, Cairo, Egypt → American University in Cairo (AUC) - New Cairo'
          : 'بنها - القاهرة',
      price: 550,
      paidAmount: n % 4 == 0 ? 0 : 550,
      remainingAmount: n % 4 == 0 ? 550 : 0,
      totalRides: n % 2 == 0 ? 20 : 0,
      usedRides: n % 2 == 0 ? 6 : 0,
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 1).add(Duration(days: n)),
    );
  }),
);

const _names = [
  'محمود يوسف',
  'سارة عبد الرحمن',
  'أحمد الشرقاوي',
  'ندى مصطفى',
  'منى صلاح',
  'خالد فؤاد',
];

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required double width,
  required double height,
  String? openSheetFor,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final datasource = _seed();
  final repository = SubscriptionsRepositoryImpl(datasource);
  final cubit = SubscriptionsCubit(
    getSubscriptions: GetSubscriptionsUseCase(repository),
    getDetails: GetSubscriptionDetailsUseCase(repository),
    createSubscription: CreateSubscriptionUseCase(repository),
    cancelSubscription: CancelSubscriptionUseCase(repository),
    renewSubscription: RenewSubscriptionUseCase(repository),
    markRideUsed: MarkSubscriptionRideUsedUseCase(repository),
    confirmPayment: ConfirmPaymentUseCase(repository),
    getCreationOptions: GetSubscriptionCreationOptionsUseCase(repository),
    getTrips: GetSubscriptionTripsUseCase(repository),
    getRideUsage: GetSubscriptionRideUsageUseCase(repository),
  );
  addTearDown(cubit.close);
  await cubit.load();

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeWithHostFont(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const SubscriptionsScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  if (openSheetFor != null) {
    // Deliberately not awaited: the returned future only resolves once the
    // sheet is dismissed, which nothing in this harness does.
    final screenContext = tester.element(find.byType(SubscriptionsScreen));
    unawaited(openSubscriptionDetails(screenContext, openSheetFor));
    await tester.pumpAndSettle();
  }

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('_captures/$name.png'),
  );
}

/// The real themes build their text theme through google_fonts, which the test
/// binding's blocked network turns into a post-test throw. The palette is the
/// real one; only the glyphs differ.
ThemeData _themeWithHostFont() {
  final scheme = darkColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: AppDarkColors.background,
    canvasColor: AppDarkColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: AppDarkColors.shadow,
    extensions: [AppSurfaceStyle.flat(scheme)],
  );
}

class Datasource implements SubscriptionsDatasource {
  Datasource(this._items);

  final List<UserSubscription> _items;

  @override
  Future<List<UserSubscription>> fetchSubscriptions() async =>
      List.unmodifiable(_items);

  @override
  Future<UserSubscription> fetchSubscriptionDetails(String id) async =>
      _items.firstWhere((s) => s.id == id);

  @override
  Future<UserSubscription> createSubscription(UserSubscription s) async => s;

  @override
  Future<UserSubscription> cancelSubscription(String id) async =>
      _items.firstWhere((s) => s.id == id);

  @override
  Future<UserSubscription> renewSubscription(String id) async =>
      _items.firstWhere((s) => s.id == id);

  @override
  Future<UserSubscription> markRideUsed(String id, {String? tripId}) async =>
      _items.firstWhere((s) => s.id == id);

  @override
  Future<UserSubscription> confirmPayment(String id) async =>
      _items.firstWhere((s) => s.id == id);

  @override
  Future<SubscriptionCreationOptions> fetchCreationOptions() async =>
      const SubscriptionCreationOptions(users: [], plans: [], routes: []);

  @override
  Future<List<SubscriptionTrip>> fetchTrips() async => [];

  @override
  Future<List<SubscriptionRideUsage>> fetchRideUsage() async => const [];
}
