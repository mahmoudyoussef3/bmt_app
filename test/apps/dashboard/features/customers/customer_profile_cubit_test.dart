import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_payment.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_trip.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/usecases/customers_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customer_profile_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customer_profile_state.dart';

import 'customers_test_fixtures.dart';

void main() {
  late FakeCustomersRepository repository;
  late CustomerProfileCubit cubit;

  CustomerProfileCubit build() => CustomerProfileCubit(
    clientId: 'client-1',
    getProfile: GetCustomerProfileUseCase(repository),
    getTrips: GetCustomerTripsUseCase(repository),
    getSubscriptions: GetCustomerSubscriptionsUseCase(repository),
    getPayments: GetCustomerPaymentsUseCase(repository),
    getActivity: GetCustomerActivityUseCase(repository),
  );

  setUp(() {
    repository = FakeCustomersRepository();
    cubit = build();
  });

  tearDown(() => cubit.close());

  group('loading', () {
    test('opens on نظرة عامة with the header already filled', () async {
      await cubit.load();

      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.tab, CustomerProfileTab.overview);
      expect(state.profile.client.fullName, 'أحمد محمود');
      expect(state.profile.metrics.bookingsTotal, 12);
    });

    test('fetches only the profile — the four tabs stay unasked', () async {
      await cubit.load();

      expect(repository.calls, ['profile']);
    });

    test('a failed profile is fatal — without it there is no header', () async {
      repository.failing.add('profile');

      await cubit.load();

      expect(cubit.state, isA<CustomerProfileErrorState>());
    });
  });

  group('lazy tabs', () {
    test('selecting a tab loads exactly that tab', () async {
      await cubit.load();
      repository.calls.clear();

      await cubit.setTab(CustomerProfileTab.subscriptions);

      expect(repository.calls, ['subscriptions']);
      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.subscriptionsStatus.loaded, isTrue);
      expect(state.subscriptions, hasLength(1));
    });

    test('re-selecting a loaded tab does not refetch', () async {
      await cubit.load();
      await cubit.setTab(CustomerProfileTab.payments);
      await cubit.setTab(CustomerProfileTab.overview);
      repository.calls.clear();

      await cubit.setTab(CustomerProfileTab.payments);

      expect(repository.calls, isEmpty);
    });

    test('الرحلات opens on القادمة', () async {
      await cubit.load();
      repository.calls.clear();

      await cubit.setTab(CustomerProfileTab.trips);

      expect(repository.calls, ['trips:upcoming']);
      expect(
        (cubit.state as CustomerProfileLoadedState).showPastTrips,
        isFalse,
      );
    });
  });

  group('partial failure', () {
    test('one broken tab leaves the header and the others intact', () async {
      repository.failing.add('payments');
      await cubit.load();

      await cubit.setTab(CustomerProfileTab.payments);
      await cubit.setTab(CustomerProfileTab.subscriptions);

      final state = cubit.state as CustomerProfileLoadedState;
      expect(
        state,
        isA<CustomerProfileLoadedState>(),
        reason: 'a tab failure must never become a page failure',
      );
      expect(state.paymentsStatus.failed, isTrue);
      expect(state.subscriptionsStatus.loaded, isTrue);
      expect(state.profile.client.fullName, 'أحمد محمود');
    });

    test('the header names every failed tab', () async {
      repository.failing.addAll({'payments', 'activity'});
      await cubit.load();

      await cubit.setTab(CustomerProfileTab.payments);
      await cubit.setTab(CustomerProfileTab.activity);

      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.failedSources, ['المدفوعات', 'النشاط']);
    });

    test('a tab nobody opened is not reported as failed', () async {
      await cubit.load();

      expect(
        (cubit.state as CustomerProfileLoadedState).failedSources,
        isEmpty,
      );
    });

    test('a failed refresh keeps the rows that already arrived', () async {
      await cubit.load();
      await cubit.setTab(CustomerProfileTab.subscriptions);
      expect(
        (cubit.state as CustomerProfileLoadedState).subscriptions,
        hasLength(1),
      );

      repository.failing.add('subscriptions');
      await cubit.loadSubscriptions(force: true);

      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.subscriptions, hasLength(1), reason: 'stale, not gone');
      expect(state.subscriptionsStatus.loaded, isTrue);
      expect(state.subscriptionsStatus.error, isNotNull);
      expect(
        state.subscriptionsStatus.failed,
        isFalse,
        reason: 'it has data, so it is stale rather than broken',
      );
    });

    test('a failed profile refresh keeps the profile on screen', () async {
      await cubit.load();
      repository.failing.add('profile');

      await cubit.refresh();

      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.profile.client.fullName, 'أحمد محمود');
      expect(state.refreshing, isFalse);
    });
  });

  group('empty customers', () {
    test('a customer with no trips loads cleanly', () async {
      repository.pastTrips = const CustomerTripsPage.empty();
      repository.upcomingTrips = const CustomerTripsPage.empty();
      await cubit.load();

      await cubit.setTab(CustomerProfileTab.trips);

      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.tripsStatus.loaded, isTrue);
      expect(state.visibleTrips.rows, isEmpty);
      expect(state.tripsPageCount, 1, reason: 'empty is still page 1 of 1');
    });

    test('a customer with no subscriptions loads cleanly', () async {
      repository.subscriptions = [];
      await cubit.load();

      await cubit.setTab(CustomerProfileTab.subscriptions);

      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.subscriptionsStatus.loaded, isTrue);
      expect(state.subscriptions, isEmpty);
    });

    test('a customer with no payments and no wallet loads cleanly', () async {
      repository.payments = const CustomerPaymentsPage.empty();
      await cubit.load();

      await cubit.setTab(CustomerProfileTab.payments);

      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.payments.rows, isEmpty);
      expect(
        state.payments.hasWallet,
        isFalse,
        reason: 'no wallet row is not a zero balance',
      );
    });

    test('a customer with several subscriptions lists them all', () async {
      repository.subscriptions = [
        subscriptionFixture(id: 'a'),
        subscriptionFixture(id: 'b', status: 'expired', isCurrent: false),
        subscriptionFixture(id: 'c', status: 'cancelled', isCurrent: false),
      ];
      await cubit.load();

      await cubit.setTab(CustomerProfileTab.subscriptions);

      expect(
        (cubit.state as CustomerProfileLoadedState).subscriptions,
        hasLength(3),
      );
    });
  });

  group('trips paging and scope', () {
    test(
      'switching to السابقة refetches that side and resets the page',
      () async {
        repository.pastTrips = CustomerTripsPage(
          total: 30,
          rows: [tripFixture()],
        );
        await cubit.load();
        await cubit.setTab(CustomerProfileTab.trips);
        repository.calls.clear();

        await cubit.showPastTrips(true);

        expect(repository.calls, ['trips:past']);
        final state = cubit.state as CustomerProfileLoadedState;
        expect(state.showPastTrips, isTrue);
        expect(state.tripsPageIndex, 0);
        expect(state.visibleTrips.total, 30);
      },
    );

    test('the two scopes are kept apart, not merged', () async {
      repository.upcomingTrips = CustomerTripsPage(
        total: 1,
        rows: [tripFixture(bookingId: 'future', status: 'confirmed')],
      );
      repository.pastTrips = CustomerTripsPage(
        total: 1,
        rows: [tripFixture(bookingId: 'history', status: 'completed')],
      );
      await cubit.load();
      await cubit.setTab(CustomerProfileTab.trips);
      await cubit.showPastTrips(true);

      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.pastTrips.rows.single.bookingId, 'history');
      expect(state.upcomingTrips.rows.single.bookingId, 'future');
    });

    test('paging asks for the next offset', () async {
      repository.pastTrips = CustomerTripsPage(
        total: 40,
        rows: [tripFixture()],
      );
      await cubit.load();
      await cubit.setTab(CustomerProfileTab.trips);
      await cubit.showPastTrips(true);

      await cubit.setTripsPage(1);

      expect((cubit.state as CustomerProfileLoadedState).tripsPageIndex, 1);
    });

    test('payments paging tracks its own index', () async {
      repository.payments = CustomerPaymentsPage(
        total: 35,
        rows: [paymentFixture()],
      );
      await cubit.load();
      await cubit.setTab(CustomerProfileTab.payments);

      await cubit.setPaymentsPage(2);

      final state = cubit.state as CustomerProfileLoadedState;
      expect(state.paymentsPageIndex, 2);
      expect(state.paymentsPageCount, 4);
    });
  });

  group('refresh', () {
    test('re-reads only the tabs already opened', () async {
      await cubit.load();
      await cubit.setTab(CustomerProfileTab.subscriptions);
      repository.calls.clear();

      await cubit.refresh();

      expect(repository.calls, containsAll(['profile', 'subscriptions']));
      expect(
        repository.calls,
        isNot(contains('payments')),
        reason: 'refreshing is not the same request as opening',
      );
      expect(repository.calls, isNot(contains('activity')));
    });
  });

  group('activity', () {
    test('a full window is flagged so it does not read as complete', () async {
      repository.activity = List.generate(
        customerActivityLimit,
        (i) => activityFixture(at: testNow.subtract(Duration(hours: i))),
      );
      await cubit.load();

      await cubit.setTab(CustomerProfileTab.activity);

      expect(
        (cubit.state as CustomerProfileLoadedState).activityWindowed,
        isTrue,
      );
    });

    test('a short feed is not flagged', () async {
      await cubit.load();

      await cubit.setTab(CustomerProfileTab.activity);

      expect(
        (cubit.state as CustomerProfileLoadedState).activityWindowed,
        isFalse,
      );
    });
  });
}
