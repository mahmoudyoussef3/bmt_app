import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/entities/location_sharing_state.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/repositories/location_repository.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/send_location_update_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/cubit/live_location_cubit.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/widgets/trip_location_auto_share.dart';

/// The 30-second cadence is only worth what the widget driving it is worth.
///
/// `TripLocationAutoShare` owns the timer through a `BlocProvider` it creates
/// itself, and it is mounted as one child of the trip-execution page's
/// `SliverList`. A sliver list builds its children lazily: an element scrolled
/// beyond the viewport *and* the cache extent is deactivated and disposed. If
/// that happens here, the provider closes the cubit, `close()` cancels the
/// timer, and the client's map goes dark — with no error, no state change, and
/// nothing on screen to tell the captain that the trip stopped reporting.
///
/// That is not something the cubit's own unit tests can see: they drive the
/// cubit directly and never scroll. These tests reproduce the page's real
/// sliver structure and scroll it the way a captain does when they check the
/// route or the passenger list mid-trip.
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
    captainGetIt.registerFactory<LiveLocationCubit>(
      () => LiveLocationCubit(
        sendLocation: captainGetIt<SendLocationUpdateUseCase>(),
      ),
    );
  });

  tearDown(() => captainGetIt.reset());

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
  });
}

/// The trip-execution page's real body: a `CustomScrollView` whose
/// `SliverList.list` holds the sharing card above a long run of content.
Widget _host() {
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
                const TripLocationAutoShare(tripId: 'trip-1', enabled: true),
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
}
