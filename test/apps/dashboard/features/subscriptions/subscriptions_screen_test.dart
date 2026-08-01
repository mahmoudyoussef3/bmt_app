import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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

import 'subscriptions_test_fixtures.dart';

/// Two subscribers on one route: one is on the trip's route inside their
/// window, the other is on a different route entirely.
class _ScreenDatasource implements SubscriptionsDatasource {
  _ScreenDatasource({required this.today});

  final DateTime today;
  final List<(String, String?)> recordedRides = [];

  late final List<UserSubscription> _items = [
    subscriptionFixture(
      id: 'sub-on-route',
      status: SubscriptionStatus.active,
      userName: 'منى صلاح',
      packageName: 'باقة شهرية',
      routeId: 'route-1',
      startDate: today.subtract(const Duration(days: 3)),
      endDate: today.add(const Duration(days: 20)),
    ),
    subscriptionFixture(
      id: 'sub-elsewhere',
      status: SubscriptionStatus.active,
      userName: 'خالد فؤاد',
      packageName: 'باقة أسبوعية',
      routeId: 'route-2',
      startDate: today.subtract(const Duration(days: 3)),
      endDate: today.add(const Duration(days: 20)),
    ),
  ];

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
  Future<UserSubscription> markRideUsed(String id, {String? tripId}) async {
    recordedRides.add((id, tripId));
    return _items.firstWhere((s) => s.id == id);
  }

  @override
  Future<UserSubscription> confirmPayment(String id) async =>
      _items.firstWhere((s) => s.id == id);

  @override
  Future<SubscriptionCreationOptions> fetchCreationOptions() async =>
      const SubscriptionCreationOptions(users: [], plans: [], routes: []);

  @override
  Future<List<SubscriptionTrip>> fetchTrips() async => [
    tripFixture(
      id: 'trip-1',
      routeId: 'route-1',
      code: 'TR-500',
      routeName: 'بنها - القاهرة',
      date: today,
    ),
  ];

  @override
  Future<List<SubscriptionRideUsage>> fetchRideUsage() async => const [];
}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  late _ScreenDatasource datasource;
  late SubscriptionsCubit cubit;

  setUp(() {
    datasource = _ScreenDatasource(today: today);
    final repository = SubscriptionsRepositoryImpl(datasource);
    cubit = SubscriptionsCubit(
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
  });

  tearDown(() => cubit.close());

  // Tall enough that the trip panel plus the first subscriber cards are all
  // laid out: a ListView only builds what it can show, so a short viewport
  // makes off-screen rows invisible to the finders rather than absent.
  Future<void> pumpScreen(
    WidgetTester tester, {
    double width = 1400,
    double height = 2600,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider.value(
              value: cubit..load(),
              child: const SubscriptionsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists every office subscriber and lays out cleanly', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('الاشتراكات'), findsOneWidget);
    expect(find.text('منى صلاح'), findsOneWidget);
    expect(find.text('خالد فؤاد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders on a narrow viewport without overflowing', (
    tester,
  ) async {
    await pumpScreen(tester, width: 700);

    expect(find.text('منى صلاح'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a trip narrows the list to that departure', (
    tester,
  ) async {
    await pumpScreen(tester);

    cubit.selectTrip('trip-1');
    await tester.pumpAndSettle();

    // Only the subscriber on the trip's route survives the filter.
    expect(find.text('منى صلاح'), findsOneWidget);
    expect(find.text('خالد فؤاد'), findsNothing);

    // …and the board explains why they are there, and on what package.
    expect(find.text('مؤهل للركوب'), findsOneWidget);
    expect(find.textContaining('باقة شهرية'), findsWidgets);
    expect(find.textContaining('مشتركو رحلة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recording a ride from the board attributes it to the trip', (
    tester,
  ) async {
    await pumpScreen(tester);

    cubit.selectTrip('trip-1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('تسجيل الركوب على هذه الرحلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(datasource.recordedRides, [('sub-on-route', 'trip-1')]);
  });

  testWidgets('clearing the trip filter restores the whole book', (
    tester,
  ) async {
    await pumpScreen(tester);

    cubit.selectTrip('trip-1');
    await tester.pumpAndSettle();
    cubit.selectTrip(null);
    await tester.pumpAndSettle();

    expect(find.text('خالد فؤاد'), findsOneWidget);
    expect(find.text('قائمة المشتركين'), findsOneWidget);
  });
}
