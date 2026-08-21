import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_filters.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/usecases/customers_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customers_state.dart';

import 'customers_test_fixtures.dart';

void main() {
  late FakeCustomersRepository repository;
  late CustomersCubit cubit;

  CustomersCubit build() => CustomersCubit(
    getOverview: GetCustomersOverviewUseCase(repository),
    getDirectory: GetCustomerDirectoryUseCase(repository),
  );

  setUp(() {
    // Session-scoped and shared between tests in a file — the console's
    // documented leak. Cleared at both ends so a remembered filter from one
    // test cannot become another's starting state.
    DashboardFilterMemory.instance.clear();
    repository = FakeCustomersRepository();
    cubit = build();
  });

  tearDown(() async {
    await cubit.close();
    DashboardFilterMemory.instance.clear();
  });

  group('loading', () {
    test(
      'starts loading, then lands on the directory with its counts',
      () async {
        expect(cubit.state, isA<CustomersLoadingState>());

        await cubit.load();

        final state = cubit.state as CustomersLoadedState;
        expect(state.page.rows, hasLength(1));
        expect(state.page.total, 1);
        expect(state.overview.totalCustomers, 8);
        expect(state.pageIndex, 0);
        expect(state.filters.isEmpty, isTrue);
      },
    );

    test(
      'a failed directory load is fatal — there is no page without it',
      () async {
        repository.failing.add('directory');

        await cubit.load();

        expect(cubit.state, isA<CustomersErrorState>());
        expect(
          (cubit.state as CustomersErrorState).message,
          contains('directory'),
        );
      },
    );

    test(
      'a failed overview keeps the list and raises the partial notice',
      () async {
        // The counts summarise a list that did arrive. Losing them is worth a
        // notice, not the page.
        repository.failing.add('overview');

        await cubit.load();

        final state = cubit.state as CustomersLoadedState;
        expect(state.overviewFailed, isTrue);
        expect(state.page.rows, hasLength(1));
        expect(state.overview.totalCustomers, 0);
      },
    );

    test('asks for exactly one page, not the whole base', () async {
      await cubit.load();

      expect(repository.lastLimit, customersPageSize);
      expect(repository.lastOffset, 0);
    });
  });

  group('search', () {
    test(
      'sends the term to the server rather than filtering locally',
      () async {
        await cubit.load();
        repository.calls.clear();

        await cubit.search('أحمد');

        expect(repository.lastFilters!.search, 'أحمد');
        expect(repository.calls, contains('directory'));
      },
    );

    test(
      'an empty search result is distinguishable from an empty base',
      () async {
        await cubit.load();
        repository.directory = const CustomerDirectoryPage(total: 0, rows: []);

        await cubit.search('لا-يوجد');

        final state = cubit.state as CustomersLoadedState;
        expect(state.isEmpty, isTrue);
        expect(state.isFilteredEmpty, isTrue, reason: 'a search is in force');
        expect(state.filters.isSearching, isTrue);
      },
    );

    test('an empty base is not reported as an empty search', () async {
      repository.directory = const CustomerDirectoryPage(total: 0, rows: []);

      await cubit.load();

      final state = cubit.state as CustomersLoadedState;
      expect(state.isEmpty, isTrue);
      expect(state.isFilteredEmpty, isFalse);
    });

    test('a slow earlier search cannot overwrite a faster later one', () async {
      await cubit.load();

      // Hold the first request open until the second has already answered.
      final firstCall = Completer<void>();
      var seen = 0;
      repository.gates['directory'] = () async {
        seen++;
        if (seen == 1) await firstCall.future;
      };

      repository.directory = CustomerDirectoryPage(
        total: 1,
        rows: [summaryFixture(fullName: 'قديم')],
      );
      final slow = cubit.search('أ');

      repository.directory = CustomerDirectoryPage(
        total: 1,
        rows: [summaryFixture(fullName: 'حديث')],
      );
      await cubit.search('أحمد');

      firstCall.complete();
      await slow;

      final state = cubit.state as CustomersLoadedState;
      expect(state.page.rows.single.fullName, 'حديث');
      expect(state.filters.search, 'أحمد');
    });
  });

  group('filtering', () {
    test('each filter reaches the server as its wire value', () async {
      await cubit.load();

      await cubit.setSubscriptionFilter(CustomerSubscriptionFilter.active);
      expect(repository.lastFilters!.subscription.wire, 'active');

      await cubit.setUpcomingFilter(CustomerUpcomingFilter.has);
      expect(repository.lastFilters!.upcoming.wire, 'has');

      await cubit.setActivityFilter(CustomerActivityFilter.dormant);
      expect(repository.lastFilters!.activity.wire, 'dormant');

      await cubit.setStatusFilter('suspended');
      expect(repository.lastFilters!.status, 'suspended');
    });

    test('a filter change resets to the first page', () async {
      repository.directory = CustomerDirectoryPage(
        total: 200,
        rows: [summaryFixture()],
      );
      await cubit.load();
      await cubit.setPage(3);
      expect((cubit.state as CustomersLoadedState).pageIndex, 3);

      await cubit.setSubscriptionFilter(CustomerSubscriptionFilter.active);

      // Staying on page 4 of a narrower result set lands on an empty table and
      // reads as "no results" for a filter that matched plenty.
      expect((cubit.state as CustomersLoadedState).pageIndex, 0);
      expect(repository.lastOffset, 0);
    });

    test('clearing resets every filter and forgets the memory', () async {
      await cubit.load();
      await cubit.search('أحمد');
      await cubit.setActivityFilter(CustomerActivityFilter.active);
      expect(
        DashboardFilterMemory.instance.read<CustomerFilters>(
          DashboardFilterIds.customers,
        ),
        isNotNull,
      );

      await cubit.clearFilters();

      final state = cubit.state as CustomersLoadedState;
      expect(state.filters.activeCount, 0);
      expect(
        DashboardFilterMemory.instance.read<CustomerFilters>(
          DashboardFilterIds.customers,
        ),
        isNull,
      );
    });

    test(
      'filters survive a rebuilt cubit, as the shell rebuilds modules',
      () async {
        await cubit.load();
        await cubit.setUpcomingFilter(CustomerUpcomingFilter.has);
        await cubit.close();

        // What the shell does on every navigation: a brand new cubit.
        cubit = build();
        await cubit.load();

        final state = cubit.state as CustomersLoadedState;
        expect(state.filters.upcoming, CustomerUpcomingFilter.has);
        expect(repository.lastFilters!.upcoming.wire, 'has');
      },
    );

    test('applyFilters replaces the whole set, as a KPI tile does', () async {
      await cubit.load();
      await cubit.search('أحمد');

      await cubit.applyFilters(
        const CustomerFilters(activity: CustomerActivityFilter.active),
      );

      final state = cubit.state as CustomersLoadedState;
      expect(state.filters.search, isEmpty);
      expect(state.filters.activity, CustomerActivityFilter.active);
    });
  });

  group('pagination', () {
    setUp(() {
      repository.directory = CustomerDirectoryPage(
        total: 60,
        rows: [summaryFixture()],
      );
    });

    test(
      'page count is derived from the matched total, not the page',
      () async {
        await cubit.load();

        // 60 rows at 25 a page.
        expect((cubit.state as CustomersLoadedState).pageCount, 3);
      },
    );

    test('turning a page asks the server for that offset', () async {
      await cubit.load();

      // Zero-based, as OpsDataTable reports it: index 2 is the third page.
      await cubit.setPage(2);

      expect(repository.lastOffset, 2 * customersPageSize);
      expect((cubit.state as CustomersLoadedState).pageIndex, 2);
    });

    test('a page beyond the last is clamped rather than requested', () async {
      await cubit.load();
      repository.calls.clear();

      await cubit.setPage(99);

      expect((cubit.state as CustomersLoadedState).pageIndex, 2);
    });

    test('re-selecting the current page makes no request', () async {
      await cubit.load();
      repository.calls.clear();

      await cubit.setPage(0);

      expect(repository.calls, isEmpty);
    });

    test('a failed page turn keeps the page and reports beside it', () async {
      await cubit.load();
      repository.failing.add('directory');

      await cubit.setPage(1);

      final state = cubit.state;
      expect(
        state,
        isA<CustomersLoadedState>(),
        reason: 'a failed action must never blank a loaded screen',
      );
      expect((state as CustomersLoadedState).actionError, isNotNull);
      expect(state.page.rows, hasLength(1));
      expect(state.listLoading, isFalse);
    });
  });

  group('refresh', () {
    test('re-reads both the page and the counts', () async {
      await cubit.load();
      repository.calls.clear();

      await cubit.refresh();

      expect(repository.calls, containsAll(['directory', 'overview']));
    });

    test('keeps the current filters and page', () async {
      repository.directory = CustomerDirectoryPage(
        total: 60,
        rows: [summaryFixture()],
      );
      await cubit.load();
      await cubit.setActivityFilter(CustomerActivityFilter.active);
      await cubit.setPage(1);

      await cubit.refresh();

      final state = cubit.state as CustomersLoadedState;
      expect(state.filters.activity, CustomerActivityFilter.active);
      expect(state.pageIndex, 1);
      expect(repository.lastOffset, customersPageSize);
    });
  });
}
