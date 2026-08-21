// The dashboard half of the product-screenshot harness.
//
// Mounts the REAL `DashboardShell` and the REAL module screens, with every
// module cubit replaced by a fake already holding a populated loaded state.
// `registerDashboardDependencies()` is never called, so nothing here can reach
// Supabase — the console renders exactly as it does in production, over
// invented data.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_shell.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_theme_cubit.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_theme_repository.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_state.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/models/booking_filters.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/models/booking_queue_tab.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/cubit/business_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/presentation/cubit/business_overview_state.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/presentation/cubit/dashboard_home_state.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/cubit/live_ops_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/cubit/live_ops_state.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_badge_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/presentation/cubit/office_profile_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_licensing/presentation/cubit/platform_licensing_state.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/presentation/cubit/office_profile_state.dart';
import 'package:bmt_app/apps/dashboard/features/reports/domain/entities/report_entities.dart';
import 'package:bmt_app/apps/dashboard/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/reports/presentation/cubit/reports_state.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/presentation/cubit/reviews_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/presentation/cubit/reviews_state.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/routes_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/routes_state.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trip_details_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_passengers/presentation/cubit/trip_passengers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_pricing/presentation/cubit/trip_pricing_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_seats/presentation/cubit/trip_seats_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/cubit/wallet_state.dart';
import 'package:bmt_app/core/security/secure_storage.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import 'dashboard_demo_data.dart' as demo;

// ── Fakes ───────────────────────────────────────────────────────────────────

import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_activity.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_filters.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_payment.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_profile.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_trip.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/repositories/customers_repository.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/usecases/customers_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/customers/presentation/cubit/customers_state.dart';

class _Storage implements SecureStorage {
  final _values = <String, String>{};
  @override
  Future<void> delete(String key) async => _values.remove(key);
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

class _FakeBusinessOverview extends Cubit<BusinessOverviewState>
    implements BusinessOverviewCubit {
  _FakeBusinessOverview()
    : super(BusinessOverviewLoaded(demo.businessOverview));
  @override
  Future<void> load() async {}
  @override
  Future<void> refresh() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeHome extends Cubit<DashboardHomeState>
    implements DashboardHomeCubit {
  _FakeHome() : super(DashboardHomeLoaded(demo.homeSummary));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeAlerts extends Cubit<OperationalAlertsState>
    implements OperationalAlertsCubit {
  _FakeAlerts() : super(const OperationalAlertsInitial());
  @override
  void startWatching() {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeBadge extends Cubit<int> implements OperationalAlertsBadgeCubit {
  _FakeBadge() : super(3);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeLiveOps extends Cubit<LiveOpsState> implements LiveOpsCubit {
  _FakeLiveOps() : super(LiveOpsLoaded(snapshot: demo.liveOps));
  @override
  Future<void> startWatching() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeTripsList extends Cubit<TripsListState> implements TripsListCubit {
  _FakeTripsList() : super(TripsListLoaded(trips: demo.trips));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeTripDetails extends Cubit<TripDetailsState>
    implements TripDetailsCubit {
  _FakeTripDetails() : super(const TripDetailsInitial());
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeTripSeats extends Cubit<TripSeatsState> implements TripSeatsCubit {
  _FakeTripSeats() : super(const TripSeatsInitial());
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeTripPricing extends Cubit<TripPricingState>
    implements TripPricingCubit {
  _FakeTripPricing() : super(const TripPricingInitial());
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeTripPassengers extends Cubit<TripPassengersState>
    implements TripPassengersCubit {
  _FakeTripPassengers() : super(const TripPassengersInitial());
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeRoutes extends Cubit<RoutesState> implements RoutesCubit {
  _FakeRoutes()
    : super(
        RoutesLoaded(
          routes: demo.routes,
          selectedRouteId: demo.routes.first.id,
        ),
      );
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeBookings extends Cubit<BookingsState> implements BookingsCubit {
  _FakeBookings()
    : super(
        BookingsLoaded(
          bookings: demo.bookings,
          filters: const BookingFilters(),
          activeTab: BookingQueueTab.all,
        ),
      );
  @override
  Future<void> load({BookingQueueTab? presetTab}) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeFleetOverview extends Cubit<FleetOverviewState>
    implements FleetOverviewCubit {
  _FakeFleetOverview() : super(FleetOverviewLoaded(demo.fleet));
  @override
  Future<void> loadWorkspace() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeFleetDrivers extends Cubit<FleetDriversState>
    implements FleetDriversCubit {
  _FakeFleetDrivers() : super(FleetDriversLoaded(drivers: demo.fleet.drivers));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeFleetVehicles extends Cubit<FleetVehiclesState>
    implements FleetVehiclesCubit {
  _FakeFleetVehicles()
    : super(FleetVehiclesLoaded(vehicles: demo.fleet.vehicles));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeFleetDocuments extends Cubit<FleetDocumentsState>
    implements FleetDocumentsCubit {
  _FakeFleetDocuments()
    : super(FleetDocumentsLoaded(documents: demo.fleet.documents));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeFinance extends Cubit<FinanceState> implements FinanceCubit {
  _FakeFinance([FinanceSection section = FinanceSection.overview])
    : super(
        FinanceLoaded(
          ledger: demo.ledger,
          refundRequests: demo.financeRefunds,
          subscriptions: demo.subscriptionRecords,
          loadedAt: demo.now,
          walletPosition: demo.walletPosition,
          section: section,
        ),
      );
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeWallet extends Cubit<WalletState> implements WalletCubit {
  _FakeWallet()
    : super(
        WalletLoadedState(
          overview: demo.walletOverview,
          directory: demo.walletDirectory,
          summary: demo.walletSummary,
          selectedClientId: 'client-0',
          refundQueue: demo.walletRefundQueue,
        ),
      );
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// العملاء's directory, already loaded.
class _FakeCustomers extends Cubit<CustomersState> implements CustomersCubit {
  _FakeCustomers()
    : super(
        CustomersLoadedState(
          overview: demo.customersOverview,
          page: CustomerDirectoryPage(
            total: demo.customers.length,
            rows: demo.customers,
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Serves the Customer 360 workspace.
///
/// A repository rather than a cubit fake, because `CustomerProfileCubit` takes
/// the client id it serves as a constructor argument and is built by the screen
/// from the use cases in the graph. Faking the repository means the harness
/// photographs the real cubit driving the real tabs.
class _ShowcaseCustomersRepository implements CustomersRepository {
  const _ShowcaseCustomersRepository();

  @override
  Future<CustomersOverview> getOverview() async => demo.customersOverview;

  @override
  Future<CustomerDirectoryPage> getDirectory({
    required CustomerFilters filters,
    required int limit,
    required int offset,
  }) async =>
      CustomerDirectoryPage(total: demo.customers.length, rows: demo.customers);

  @override
  Future<CustomerProfile> getProfile(String clientId) async =>
      demo.showcaseCustomerProfile;

  @override
  Future<CustomerTripsPage> getTrips(
    String clientId, {
    required bool upcoming,
    required int limit,
    required int offset,
  }) async => upcoming
      ? const CustomerTripsPage.empty()
      : demo.showcaseCustomerPastTrips;

  @override
  Future<List<CustomerSubscription>> getSubscriptions(String clientId) async =>
      demo.showcaseCustomerSubscriptions;

  @override
  Future<CustomerPaymentsPage> getPayments(
    String clientId, {
    required int limit,
    required int offset,
  }) async => demo.showcaseCustomerPayments;

  @override
  Future<List<CustomerActivityEvent>> getActivity(String clientId) async =>
      demo.showcaseCustomerActivity;
}

class _FakeReports extends Cubit<ReportsState> implements ReportsCubit {
  _FakeReports()
    : super(
        ReportsLoaded(
          activeReportType: ReportType.trips,
          filter: demo.reportFilter,
          reportData: demo.tripsReport,
          availableRoutes: const ['CAI-ALX', 'CAI-HRG', 'CAI-AST', 'MNF-CAI'],
          availableDrivers: const [
            'أحمد علي حسن',
            'محمد سعيد عبد الله',
            'خالد إبراهيم فؤاد',
          ],
          availableVehicles: const ['ن ص ٤٢٧', 'ب ط ١٩٣', 'ق ر ٦٥٨'],
          availablePackages: const [
            'باقة شهرية — 20 رحلة',
            'باقة أسبوعية — 8 رحلات',
          ],
        ),
      );
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeReviews extends Cubit<ReviewsState> implements ReviewsCubit {
  _FakeReviews() : super(ReviewsLoaded(reviews: demo.reviews));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeOfficeProfile extends Cubit<OfficeProfileState>
    implements OfficeProfileCubit {
  _FakeOfficeProfile() : super(OfficeProfileLoaded(demo.officeProfile));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// The SaaS side of the console: the plan catalogue offices are licensed on.
class _FakeLicensing extends Cubit<PlatformLicensingState>
    implements PlatformLicensingCubit {
  _FakeLicensing()
    : super(
        PlatformLicensingLoaded(
          plans: demo.licensingPlans,
          settings: demo.licensingSettings,
        ),
      );
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ── Wiring ──────────────────────────────────────────────────────────────────

void registerDashboardShowcaseFakes() {
  dashboardDi
    ..registerFactory<BusinessOverviewCubit>(_FakeBusinessOverview.new)
    ..registerFactory<DashboardHomeCubit>(_FakeHome.new)
    ..registerFactory<OperationalAlertsCubit>(_FakeAlerts.new)
    ..registerLazySingleton<OperationalAlertsBadgeCubit>(_FakeBadge.new)
    ..registerFactory<LiveOpsCubit>(_FakeLiveOps.new)
    ..registerFactory<TripsListCubit>(_FakeTripsList.new)
    ..registerFactory<TripDetailsCubit>(_FakeTripDetails.new)
    ..registerFactory<TripSeatsCubit>(_FakeTripSeats.new)
    ..registerFactory<TripPricingCubit>(_FakeTripPricing.new)
    ..registerFactory<TripPassengersCubit>(_FakeTripPassengers.new)
    ..registerFactory<RoutesCubit>(_FakeRoutes.new)
    ..registerFactory<BookingsCubit>(_FakeBookings.new)
    ..registerFactory<FleetOverviewCubit>(_FakeFleetOverview.new)
    ..registerFactory<FleetDriversCubit>(_FakeFleetDrivers.new)
    ..registerFactory<FleetVehiclesCubit>(_FakeFleetVehicles.new)
    ..registerFactory<FleetDocumentsCubit>(_FakeFleetDocuments.new)
    ..registerFactory<FinanceCubit>(() => _FakeFinance(_financeSection))
    ..registerFactory<WalletCubit>(_FakeWallet.new)
    ..registerFactory<CustomersCubit>(_FakeCustomers.new)
    // The profile workspace resolves these from the graph, so the harness
    // registers the real use cases over a fake repository.
    ..registerLazySingleton<CustomersRepository>(
      () => const _ShowcaseCustomersRepository(),
    )
    ..registerLazySingleton(
      () => GetCustomerProfileUseCase(dashboardDi<CustomersRepository>()),
    )
    ..registerLazySingleton(
      () => GetCustomerTripsUseCase(dashboardDi<CustomersRepository>()),
    )
    ..registerLazySingleton(
      () => GetCustomerSubscriptionsUseCase(dashboardDi<CustomersRepository>()),
    )
    ..registerLazySingleton(
      () => GetCustomerPaymentsUseCase(dashboardDi<CustomersRepository>()),
    )
    ..registerLazySingleton(
      () => GetCustomerActivityUseCase(dashboardDi<CustomersRepository>()),
    )
    ..registerFactory<ReportsCubit>(_FakeReports.new)
    ..registerFactory<ReviewsCubit>(_FakeReviews.new)
    ..registerFactory<OfficeProfileCubit>(_FakeOfficeProfile.new)
    ..registerFactory<PlatformLicensingCubit>(_FakeLicensing.new);
}

/// Which money tab the next `FinanceCubit` opens on. The section lives in the
/// loaded state, so the screen can be photographed on its analytics and reports
/// tabs — the surfaces the console's commented-out reports nav item no longer
/// reaches directly.
FinanceSection _financeSection = FinanceSection.overview;

const OfficeContext showcaseOffice = OfficeContext(
  officeId: 'office-1',
  officeName: demo.officeName,
  officeSlug: 'nile-transport',
  role: DashboardRole.admin,
  username: 'nile.ops',
  fullName: 'محمود يوسف',
  listingStatus: 'listed',
  isPlatformAdmin: true,
);

/// Screen id → the console route it opens.
const Map<String, String> dashboardScreens = {
  'dashboard-executive-overview': DashboardRoutes.businessOverview,
  'dashboard-home': DashboardRoutes.home,
  'dashboard-live-ops': DashboardRoutes.liveOps,
  'dashboard-trips': DashboardRoutes.trips,
  'dashboard-routes': DashboardRoutes.routes,
  'dashboard-bookings': DashboardRoutes.bookings,
  'dashboard-fleet': DashboardRoutes.fleet,
  'dashboard-finance': DashboardRoutes.payments,
  'dashboard-finance-ledger': DashboardRoutes.payments,
  'dashboard-finance-analytics': DashboardRoutes.payments,
  'dashboard-finance-reports': DashboardRoutes.payments,
  'dashboard-customers': DashboardRoutes.customers,
  'dashboard-wallet': DashboardRoutes.wallet,
  'dashboard-reports': DashboardRoutes.reports,
  'dashboard-reviews': DashboardRoutes.reviews,
  'dashboard-office-profile': DashboardRoutes.officeProfile,

  // «الخطط والباقات» folded into «الباقات والميزات» when the platform console
  // went from seven sidebar rows to four; the old `platformPlans` constant went
  // with it, and this map still named it — which broke the whole harness build,
  // not just this one screen.
  'dashboard-licensing-plans': DashboardRoutes.platformCatalog,
  'dashboard-licensing-licenses': DashboardRoutes.platformLicenses,
};

Widget buildDashboardShowcase(String screenId, {bool dark = false}) {
  final route = dashboardScreens[screenId] ?? DashboardRoutes.home;
  _financeSection = switch (screenId) {
    'dashboard-finance-ledger' => FinanceSection.ledger,
    'dashboard-finance-analytics' => FinanceSection.analytics,
    'dashboard-finance-reports' => FinanceSection.reports,
    _ => FinanceSection.overview,
  };
  return BlocProvider(
    create: (_) =>
        DashboardThemeCubit(DashboardThemeRepository(storage: _Storage())),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: DashboardAppTheme.light(),
      darkTheme: DashboardAppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: DashboardShell(office: showcaseOffice, initialRoute: route),
    ),
  );
}
