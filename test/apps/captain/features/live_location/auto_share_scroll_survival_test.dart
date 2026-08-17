import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/entities/location_sharing_state.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/repositories/location_repository.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/publish_trip_location_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/watch_publishable_location_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/send_location_update_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/cubit/live_location_cubit.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/widgets/trip_location_auto_share.dart';
import 'package:bmt_app/core/tracking/vehicle_fix.dart';

/// The 30-second cadence is only worth what survives a captain using the page.
///
/// `TripLocationAutoShare` is mounted as one child of the trip-execution page's
/// `SliverList`, and a sliver list builds its children lazily: an element
/// scrolled beyond the viewport *and* the cache extent is deactivated and
/// disposed. When the widget owned the cubit, that disposal closed it, `close()`
/// cancelled the timer, and the client's map went dark — with no error, no state
/// change, and nothing on screen to tell the captain the trip had stopped
/// reporting.
///
/// The publisher is now an app-lifetime singleton, so a disposed card cannot
/// take reporting down with it. These tests keep the scroll scenario that found
/// the original defect and hold the invariant it produced: the cadence is a
/// property of the trip, not of what part of the page is on screen.
/// `live_location_publisher_test.dart` covers the ownership rules themselves.
void main() {
  late _RecordingRepository repository;

  setUp(() {
    repository = _RecordingRepository();
    // Mirrors the registrations in `captain_di.dart`, with the GPS-backed
    // datasource replaced so nothing here touches a real device sensor.
    captainGetIt.registerLazySingleton<LocationRepository>(() => repository);
    captainGetIt.registerLazySingleton<SendLocationUpdateUseCase>(
      () => SendLocationUpdateUseCase(captainGetIt<LocationRepository>()),
    );
    // A singleton, as in `captain_di.dart`: position reporting belongs to the
    // trip, not to whichever widget built a cubit first.
    captainGetIt.registerLazySingleton<LiveLocationCubit>(
      () => LiveLocationCubit(
        sendLocation: captainGetIt<SendLocationUpdateUseCase>(),
        watchPublishableLocation: WatchPublishableLocationUseCase(
          captainGetIt<LocationRepository>(),
        ),
        publishLocation: PublishTripLocationUseCase(
          captainGetIt<LocationRepository>(),
        ),
      ),
    );
  });

  // The publisher deliberately outlives the widget tree now, so the test has to
  // stop it explicitly — the same thing sign-out does in `captain/main.dart`.
  // Without this the framework fails the test on a pending timer, which is the
  // survival behaviour being asserted, not a leak.
  tearDown(() async {
    captainGetIt<LiveLocationCubit>().stopAutoSharing();
    await captainGetIt.reset();
  });

  testWidgets('keeps reporting while the captain scrolls the trip page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump(); // post-frame callback starts the timer
    await tester.pump();

    expect(
      repository.sends,
      1,
      reason: 'a departing trip reports immediately, not after a full interval',
    );

    // The captain scrolls down to read the route and the manifest — the
    // sharing card leaves the viewport entirely.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
    await tester.pump();

    // A full interval passes while they are looking further down the page.
    await tester.pump(kAutoLocationInterval);
    await tester.pump();

    expect(
      repository.sends,
      greaterThan(1),
      reason:
          'location sharing must survive scrolling: the trip is still under '
          'way, so the client map must keep moving whatever part of the page '
          'the captain happens to be looking at',
    );

    // End the trip. The publisher outlives the widget tree by design, so
    // something has to stop it, and `enabled: false` is exactly what the real
    // page does when the captain finishes — exercising the stop path rather
    // than reaching into the cubit.
    await tester.pumpWidget(_host(enabled: false));
    await tester.pump();
    await tester.pump();
  });

  testWidgets('reports on the same cadence whether scrolled or not', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump();
    await tester.pump();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
    await tester.pump();

    final before = repository.sends;
    for (var tick = 0; tick < 3; tick++) {
      await tester.pump(kAutoLocationInterval);
      await tester.pump();
    }

    expect(
      repository.sends - before,
      3,
      reason: 'three intervals scrolled away must still produce three fixes',
    );

    // End the trip. The publisher outlives the widget tree by design, so
    // something has to stop it, and `enabled: false` is exactly what the real
    // page does when the captain finishes — exercising the stop path rather
    // than reaching into the cubit.
    await tester.pumpWidget(_host(enabled: false));
    await tester.pump();
    await tester.pump();
  });
}

/// The trip-execution page's real body: a `CustomScrollView` whose
/// `SliverList.list` holds the sharing card above a long run of content.
Widget _host({bool enabled = true}) {
  return MaterialApp(
    theme: CaptainTheme.light(),
    locale: const Locale('ar'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverList.list(
              children: [
                TripLocationAutoShare(tripId: 'trip-1', enabled: enabled),
                // Stands in for the next-stop banner, route timeline, tools and
                // manifest that sit below the card on the real page.
                for (var i = 0; i < 12; i++)
                  SizedBox(height: 300, child: Text('block $i')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecordingRepository implements LocationRepository {
  int sends = 0;

  @override
  Future<LocationUpdateData> sendLocation(String tripId) async {
    sends++;
    return LocationUpdateData(
      tripId: tripId,
      latitude: 30.0444,
      longitude: 31.2357,
      recordedAt: DateTime.now(),
    );
  }

  /// The GPS stream is silent in tests: no device sensor, and nothing here needs
  /// one. That leaves the heartbeat as the only publisher, which is exactly the
  /// pre-stream behaviour these tests were written against — so what they assert
  /// about ownership and cadence still means the same thing.
  @override
  Stream<VehicleFix> watchDevicePosition() => const Stream<VehicleFix>.empty();

  @override
  Future<LocationUpdateData> publishFix(String tripId, VehicleFix fix) =>
      sendLocation(tripId);
}
