// The Client half of the product-screenshot harness.
//
// Mounts the REAL rider screens with every cubit replaced by a fake already
// holding a populated loaded state. `registerClientDependencies()` is never
// called, so nothing here can reach Supabase.
//
// The booking flow shown is the wizard — the funnel a rider can actually reach.
// `ClientRouter` deliberately does not register the older standalone
// seat-selection → checkout pair, so those screens are not showcased either.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/core/theme/client_app_theme.dart';
import 'package:bmt_app/apps/client/core/theme/client_theme.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_step_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_packages_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_packages_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_results_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_results_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/booking_wizard_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/route_selection_screen.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_state.dart';
import 'package:bmt_app/apps/client/features/home/presentation/screens/client_shell_screen.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_state.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/screens/loyalty_screen.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notification_badge_cubit.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/office_profile_cubit.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/office_profile_state.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/offices_directory_cubit.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/offices_directory_state.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/screens/office_profile_screen.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/screens/offices_directory_screen.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/screens/routes_directory_screen.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/my_subscription_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/my_subscription_state.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_state.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/screens/my_subscription_screen.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/domain/repositories/payment_repository.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/get_payment_methods_usecase.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_directory_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_directory_state.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_state.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_bloc.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_event.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_state.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/core/tracking/link_health.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/my_trips_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/cubit/client_wallet_cubit.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/screens/client_wallet_screen.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import 'client_demo_data.dart' as demo;

// ── Fakes ───────────────────────────────────────────────────────────────────

class _FakeHome extends Cubit<HomeState> implements HomeCubit {
  _FakeHome() : super(HomeLoaded(demo.homeData));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeDirectory extends Cubit<OfficesDirectoryState>
    implements OfficesDirectoryCubit {
  _FakeDirectory() : super(const OfficesDirectoryLoaded(demo.offices));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// Home's hero search card is a real form, so the harness hands it a query
/// that is already filled in — an empty card says nothing about the design.
class _FakeBookingSearch extends Cubit<BookingSearchState>
    implements BookingSearchCubit {
  _FakeBookingSearch()
    : super(
        const BookingSearchState(
          query: demo.searchQuery,
          optionsStatus: SearchOptionsStatus.loaded,
        ),
      );
  @override
  void init(BookingSearchQuery initial, {required String todayDate}) {}
  @override
  Future<void> loadOptions() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// The hero's bell badge. A hard-coded count so the harness shows the badge
/// rather than the bare bell — the real cubit would open a Supabase stream.
class _FakeNotificationBadge extends Cubit<int>
    implements NotificationBadgeCubit {
  _FakeNotificationBadge() : super(2);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeRoutesDirectory extends Cubit<RoutesDirectoryState>
    implements RoutesDirectoryCubit {
  _FakeRoutesDirectory() : super(RoutesDirectoryLoaded(demo.featuredRoutes));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeOfficeProfile extends Cubit<OfficeProfileState>
    implements OfficeProfileCubit {
  _FakeOfficeProfile()
    : super(
        OfficeProfileLoaded(routes: demo.officeRoutes, trips: demo.officeTrips),
      );
  @override
  Future<void> load(String officeId) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeTrips extends Cubit<TripsState> implements TripsCubit {
  _FakeTrips() : super(TripsLoaded(trips: demo.trips));
  @override
  Future<void> loadTrips() async {}
  @override
  Future<void> loadTripDetails(String? tripId) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// Trip details opens on one booking, so the selected trip is already resolved.
class _FakeTripDetails extends Cubit<TripsState> implements TripsCubit {
  _FakeTripDetails()
    : super(TripsLoaded(trips: demo.trips, selectedTrip: demo.confirmedTrip));
  @override
  Future<void> loadTrips() async {}
  @override
  Future<void> loadTripDetails(String? tripId) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeRouteResults extends Cubit<RouteResultsState>
    implements RouteResultsCubit {
  _FakeRouteResults()
    : super(
        RouteResultsLoaded(
          routes: demo.routeResults,
          selectedRouteId: demo.bookingRoute.id,
        ),
      );
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeSeats extends Cubit<SeatSelectionState>
    implements SeatSelectionCubit {
  _FakeSeats()
    : super(
        SeatSelectionLoaded(data: demo.seatSelection, selectedSeatId: 'seat-1'),
      );
  @override
  Future<void> loadSeatSelection(String tripId) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakePackages extends Cubit<PackagesState> implements PackagesCubit {
  _FakePackages() : super(const PackagesLoaded(packages: demo.packages));
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// Route Details' plans shelf, already holding the operator's catalogue so the
/// section is photographed populated rather than mid-fetch.
class _FakeRoutePackages extends Cubit<RoutePackagesState>
    implements RoutePackagesCubit {
  _FakeRoutePackages() : super(const RoutePackagesLoaded(demo.packages));
  @override
  Future<void> loadFor(String officeId) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeMySubscription extends Cubit<MySubscriptionState>
    implements MySubscriptionCubit {
  _FakeMySubscription() : super(MySubscriptionLoaded(demo.mySubscription));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeWallet extends Cubit<ClientWalletState>
    implements ClientWalletCubit {
  // Opened on the first office's ledger: a wallet screen with every office
  // collapsed shows balances but not what the wallet actually records.
  _FakeWallet()
    : super(ClientWalletLoaded(summary: demo.wallet, expandedWalletId: 'w-1'));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeTracking extends Cubit<TrackingState> implements TrackingCubit {
  _FakeTracking() : super(TrackingLoaded(data: demo.trackingTrip));
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeLiveTracking extends Bloc<LiveTrackingEvent, LiveTrackingState>
    implements LiveTrackingBloc {
  _FakeLiveTracking()
    : super(
        LiveTrackingActive(
          fix: demo.trackingTrip.vehicleFix!,
          receivedAt: demo.now,
          freshness: TrackingFreshness.live,
          link: TrackingLink.connected,
          progress: demo.trackingProgress,
        ),
      );
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeLoyalty extends Cubit<LoyaltyState> implements LoyaltyCubit {
  _FakeLoyalty() : super(LoyaltyLoaded(demo.loyalty));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeConfirm extends Cubit<BookingWizardConfirmState>
    implements BookingWizardConfirmCubit {
  _FakeConfirm() : super(const BookingWizardConfirmIdle());
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// The payment step reads its method tiles through the use case rather than a
/// cubit, so the fake is a repository the real use case is built over.
class _FakePaymentRepository implements PaymentRepository {
  @override
  Future<List<PaymentMethodData>> getPaymentMethods() async =>
      demo.paymentMethods;
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ── Wiring ──────────────────────────────────────────────────────────────────

void registerClientShowcaseFakes() {
  clientGetIt
    ..registerFactory<HomeCubit>(_FakeHome.new)
    ..registerFactory<OfficesDirectoryCubit>(_FakeDirectory.new)
    ..registerFactory<RoutesDirectoryCubit>(_FakeRoutesDirectory.new)
    ..registerFactory<BookingSearchCubit>(_FakeBookingSearch.new)
    ..registerLazySingleton<NotificationBadgeCubit>(_FakeNotificationBadge.new)
    ..registerFactory<OfficeProfileCubit>(_FakeOfficeProfile.new)
    ..registerFactory<TripsCubit>(_FakeTrips.new)
    ..registerFactory<RouteResultsCubit>(_FakeRouteResults.new)
    ..registerFactory<RoutePackagesCubit>(_FakeRoutePackages.new)
    ..registerFactory<SeatSelectionCubit>(_FakeSeats.new)
    ..registerFactory<PackagesCubit>(_FakePackages.new)
    ..registerFactory<MySubscriptionCubit>(_FakeMySubscription.new)
    ..registerFactory<ClientWalletCubit>(_FakeWallet.new)
    ..registerFactory<TrackingCubit>(_FakeTracking.new)
    ..registerFactory<LiveTrackingBloc>(_FakeLiveTracking.new)
    ..registerFactory<LoyaltyCubit>(_FakeLoyalty.new)
    ..registerFactory<BookingWizardConfirmCubit>(_FakeConfirm.new)
    ..registerLazySingleton<GetPaymentMethodsUseCase>(
      () => GetPaymentMethodsUseCase(_FakePaymentRepository()),
    );
}

/// Drives the real wizard to the step being photographed by replaying the
/// rider's own choices through [BookingWizardCubit] — no step is faked.
BookingWizardCubit _wizardSession({required int step}) {
  final cubit = BookingWizardCubit(demo.bookingRoute);
  final route = demo.bookingRoute;
  if (step >= 1) {
    cubit
      ..selectPickup(route.points.first)
      ..selectDropoff(route.points.last);
  }
  if (step >= 2) {
    // The seat step itself is photographed after the rider has picked a seat —
    // an empty seat map says nothing about what the step does.
    cubit
      ..selectTrip(demo.middayTrip)
      ..selectSeat('seat-1', 'A3');
  }
  // Card is the one method that settles without a receipt upload, so the pay
  // bar is photographed ready rather than blocked on a missing attachment.
  if (step >= 5) cubit.selectPaymentMethod('credit_card');
  return cubit;
}

Widget _wizardAt(int step) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<BookingWizardCubit>(
        create: (_) => _wizardSession(step: step),
      ),
      BlocProvider<BookingWizardStepCubit>(
        create: (_) => BookingWizardStepCubit()..editStep(step),
      ),
      BlocProvider<BookingWizardConfirmCubit>(
        create: (_) => clientGetIt<BookingWizardConfirmCubit>(),
      ),
    ],
    child: const BookingWizardScreen(),
  );
}

/// Screen id → the widget it mounts, in the same scope the router gives it.
final Map<String, Widget Function()> clientScreens = {
  'client-home': () => ClientShellScreen(
    routesBuilder: (_) => const SizedBox.shrink(),
    tripsBuilder: (_) => const SizedBox.shrink(),
    profileBuilder: (_) => const SizedBox.shrink(),
    notificationsBuilder: (_) => const SizedBox.shrink(),
  ),
  'client-offices': () => BlocProvider<OfficesDirectoryCubit>(
    create: (_) => clientGetIt<OfficesDirectoryCubit>(),
    child: const OfficesDirectoryScreen(),
  ),
  'client-routes': () => BlocProvider<RoutesDirectoryCubit>(
    create: (_) => clientGetIt<RoutesDirectoryCubit>(),
    child: RoutesDirectoryScreen(onOpenRoute: (_, [_]) {}),
  ),
  'client-office-profile': () => BlocProvider<OfficeProfileCubit>(
    create: (_) => clientGetIt<OfficeProfileCubit>(),
    child: OfficeProfileScreen(office: demo.nileOffice),
  ),
  'client-route-results': () => MultiBlocProvider(
    providers: [
      BlocProvider<RouteResultsCubit>(
        create: (_) => clientGetIt<RouteResultsCubit>(),
      ),
      BlocProvider<RoutePackagesCubit>(
        create: (_) => clientGetIt<RoutePackagesCubit>(),
      ),
    ],
    child: const RouteSelectionScreen(query: demo.searchQuery),
  ),
  'client-booking-trip': () => _wizardAt(1),
  'client-booking-seat': () => _wizardAt(2),
  'client-booking-package': () => _wizardAt(3),
  'client-booking-summary': () => _wizardAt(4),
  'client-booking-payment': () => _wizardAt(5),
  'client-my-trips': () => BlocProvider<TripsCubit>(
    create: (_) => clientGetIt<TripsCubit>(),
    child: MyTripsScreen(onOpenRoute: (_, [_]) {}, showBackButton: true),
  ),
  'client-trip-details': () => BlocProvider<TripsCubit>(
    create: (_) => _FakeTripDetails(),
    child: const TripDetailsScreen(tripId: 'b-1'),
  ),
  'client-my-subscription': () => BlocProvider<MySubscriptionCubit>(
    create: (_) => clientGetIt<MySubscriptionCubit>(),
    child: const MySubscriptionScreen(),
  ),
  'client-wallet': () => BlocProvider<ClientWalletCubit>(
    create: (_) => clientGetIt<ClientWalletCubit>(),
    child: const ClientWalletScreen(),
  ),
  'client-loyalty': () => BlocProvider<LoyaltyCubit>(
    create: (_) => clientGetIt<LoyaltyCubit>(),
    child: const LoyaltyScreen(),
  ),
  'client-tracking': () => MultiBlocProvider(
    providers: [
      BlocProvider<TrackingCubit>(create: (_) => clientGetIt<TrackingCubit>()),
      BlocProvider<LiveTrackingBloc>(
        create: (_) => clientGetIt<LiveTrackingBloc>(),
      ),
    ],
    child: const TrackingScreen(bookingId: 'demo-booking-1'),
  ),
};

Widget buildClientShowcase(String screenId, {bool dark = false}) {
  final builder = clientScreens[screenId]!;
  return ClientAppTheme(
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    setThemeMode: (_) {},
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ClientTheme.light(),
      darkTheme: ClientTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Builder(builder: (_) => builder()),
    ),
  );
}
