// The Captain half of the product-screenshot harness.
//
// Mounts the REAL captain pages — which self-provide their cubits from
// `captainGetIt` — with every one of those cubits replaced by a fake holding a
// populated state. `registerCaptainDependencies()` is never called, so nothing
// reaches Supabase, and no cubit here ever touches the device GPS: the map's
// position fix is invented data, not a live sensor read.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_cubit.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/cubit/assigned_trips_cubit.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/cubit/assigned_trips_state.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/cubit/live_location_cubit.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/cubit/live_location_state.dart';
import 'package:bmt_app/apps/captain/features/notifications/presentation/cubit/captain_notification_badge_cubit.dart';
import 'package:bmt_app/apps/captain/features/notifications/presentation/cubit/captain_notifications_cubit.dart';
import 'package:bmt_app/apps/captain/features/notifications/presentation/cubit/captain_notifications_state.dart';
import 'package:bmt_app/apps/captain/features/notifications/presentation/pages/captain_notifications_page.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/cubit/passenger_manifest_cubit.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/cubit/passenger_manifest_state.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/pages/passenger_list_page.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_cubit.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/cubit/trip_execution_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/cubit/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/pages/trip_execution_page.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_state.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/utils/trip_history_filters.dart';
import 'package:bmt_app/apps/captain/features/trip_map/presentation/cubit/captain_trip_map_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_map/presentation/cubit/captain_trip_map_state.dart';
import 'package:bmt_app/apps/captain/features/trip_map/presentation/pages/captain_trip_map_page.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import 'captain_demo_data.dart' as demo;

// ── Fakes ───────────────────────────────────────────────────────────────────

class _FakeAssignedTrips extends Cubit<AssignedTripsState>
    implements AssignedTripsCubit {
  _FakeAssignedTrips() : super(AssignedTripsLoaded(demo.assignedTrips));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeTripHistory extends Cubit<TripHistoryState>
    implements TripHistoryCubit {
  _FakeTripHistory()
    : super(
        TripHistoryLoaded(
          totalTrips: demo.historyTrips.length,
          totalPassengers: 86,
          groups: demo.historyGroups,
          matchCount: demo.historyTrips.length,
          filterCounts: {
            TripHistoryDateFilter.all: demo.historyTrips.length,
            TripHistoryDateFilter.today: 1,
            TripHistoryDateFilter.thisWeek: 6,
            TripHistoryDateFilter.thisMonth: demo.historyTrips.length,
          },
          query: '',
          dateFilter: TripHistoryDateFilter.all,
        ),
      );
  @override
  Future<void> load() async {}
  @override
  Future<void> refresh() async {}
  @override
  void search(String query) {}
  @override
  void filterByDate(TripHistoryDateFilter filter) {}
  @override
  void clearFilters() {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeDriverProfile extends Cubit<DriverProfileState>
    implements DriverProfileCubit {
  _FakeDriverProfile() : super(DriverProfileLoaded(demo.driverProfile));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeBadge extends Cubit<int> implements CaptainNotificationBadgeCubit {
  _FakeBadge() : super(2);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeNotifications extends Cubit<CaptainNotificationsState>
    implements CaptainNotificationsCubit {
  _FakeNotifications() : super(CaptainNotificationsLoaded(demo.notifications));
  @override
  void startWatching() {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeExecution extends Cubit<TripExecutionCubitState>
    implements TripExecutionCubit {
  _FakeExecution() : super(const TripExecutionIdle(demo.executionSnapshot));
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeManifest extends Cubit<PassengerManifestState>
    implements PassengerManifestCubit {
  _FakeManifest()
    : super(
        const PassengerManifestLoaded(
          visiblePassengers: demo.passengers,
          counts: demo.passengerCounts,
          search: '',
          statusFilter: null,
        ),
      );
  @override
  Future<void> load(String tripId) async {}
  @override
  void search(String query) {}
  @override
  void toggleStatusFilter(PassengerBoardingStatus status) {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// Holds a fixed position instead of subscribing to the device's location
/// stream — the harness must never open a GPS session.
class _FakeTripMap extends Cubit<CaptainTripMapState>
    implements CaptainTripMapCubit {
  _FakeTripMap() : super(demo.tripMap);
  // The map hands these to its controls as tear-offs, so they must be real
  // members — `noSuchMethod` would return null into a non-nullable callback.
  @override
  Future<void> start(AssignedTrip trip) async {}
  @override
  Future<void> retryLocation() async {}
  @override
  Future<void> confirmBoarded(String tripPassengerId) async {}
  @override
  Future<void> markAbsent(String tripPassengerId) async {}
  @override
  Future<void> markPending(String tripPassengerId) async {}
  @override
  Future<void> markArrivedAtActivePickup() async {}
  @override
  void clearActionError() {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// The trip-execution screen keeps the auto-share widget mounted for the whole
/// trip. The real cubit reads the device GPS and writes fixes to the database
/// on a timer; this one holds a settled "sharing" state and does neither.
class _FakeLiveLocation extends Cubit<LiveLocationState>
    implements LiveLocationCubit {
  _FakeLiveLocation()
    : super(
        LiveLocationReady(
          lastSentAt: DateTime.now().subtract(const Duration(seconds: 18)),
          isAutoSharing: true,
        ),
      );
  @override
  Future<void> send(String tripId) async {}
  @override
  void startAutoSharing(String tripId) {}
  @override
  void stopAutoSharing({String? tripId}) {}
  @override
  void resumeIfStale() {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeTheme extends Cubit<CaptainThemeState> implements CaptainThemeCubit {
  _FakeTheme(ThemeMode mode) : super(CaptainThemeState(themeMode: mode));
  @override
  Future<void> load() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ── Wiring ──────────────────────────────────────────────────────────────────

void registerCaptainShowcaseFakes() {
  captainGetIt
    ..registerFactory<AssignedTripsCubit>(_FakeAssignedTrips.new)
    ..registerFactory<TripHistoryCubit>(_FakeTripHistory.new)
    ..registerFactory<DriverProfileCubit>(_FakeDriverProfile.new)
    ..registerLazySingleton<CaptainNotificationBadgeCubit>(_FakeBadge.new)
    ..registerFactory<CaptainNotificationsCubit>(_FakeNotifications.new)
    ..registerFactory<TripExecutionCubit>(_FakeExecution.new)
    ..registerFactory<PassengerManifestCubit>(_FakeManifest.new)
    ..registerFactory<CaptainTripMapCubit>(_FakeTripMap.new)
    ..registerLazySingleton<LiveLocationCubit>(_FakeLiveLocation.new);
}

/// Screen id → the widget the router mounts for it.
final Map<String, Widget Function()> captainScreens = {
  'captain-home': () => const CaptainAppShell(),
  'captain-trip-execution': () => TripExecutionPage(trip: demo.liveTrip),
  'captain-trip-map': () => CaptainTripMapPage(trip: demo.liveTrip),
  'captain-passengers': () => const PassengerListPage(tripId: 'T-2423'),
  'captain-notifications': () => const CaptainNotificationsPage(),
};

Widget buildCaptainShowcase(String screenId, {bool dark = false}) {
  final builder = captainScreens[screenId]!;
  final mode = dark ? ThemeMode.dark : ThemeMode.light;
  return BlocProvider<CaptainThemeCubit>(
    create: (_) => _FakeTheme(mode),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: CaptainTheme.light(),
      darkTheme: CaptainTheme.dark(),
      themeMode: mode,
      home: Builder(builder: (_) => builder()),
    ),
  );
}
