import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_item.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_stop.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/repositories/trip_history_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/usecases/get_trip_stops_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_detail_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/pages/trip_history_detail_page.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// The detail page builds its own cubit out of the captain's service locator,
/// so it is pumped here through a stubbed registration rather than a provider —
/// that is the same path the router takes, and it is what proves the page wires
/// itself up, not just that its widgets lay out.
///
/// Note these assertions are deliberately conservative: `flutter_test` swaps in
/// a test font whose glyphs are far wider than Cairo's, so Arabic strings
/// measure much longer here than on a device. Passing therefore proves the
/// layout holds with room to spare, but a failure is not automatically a
/// user-visible bug — check the real font before contorting a layout to satisfy
/// this file.
class _FakeTripHistoryRepository implements TripHistoryRepository {
  _FakeTripHistoryRepository({this.stops = const [], this.failure});

  final List<TripHistoryStop> stops;
  final Object? failure;

  @override
  Future<List<TripHistoryItem>> getTripHistory() async => const [];

  @override
  Future<List<TripHistoryStop>> getTripStops(String tripId) async {
    if (failure case final error?) throw error;
    return stops;
  }
}

TripHistoryItem _trip({
  String route = 'القاهرة - الإسكندرية الطريق الصحراوي',
  int boarded = 18,
  String plate = 'ط ن ج 4821',
}) {
  final departure = DateTime(2026, 7, 16, 7, 5);
  return TripHistoryItem(
    id: 't1',
    route: route,
    tripDate: departure,
    departureTime: departure,
    arrivalTime: departure.add(const Duration(hours: 3, minutes: 25)),
    passengerCount: 20,
    boardedCount: boarded,
    vehicleNumber: 'BUS-104',
    plateNumber: plate,
  );
}

const _stops = [
  TripHistoryStop(name: 'موقف عبود', order: 0, scheduledTime: '07:05'),
  TripHistoryStop(name: 'محطة مسطرد', order: 1, scheduledTime: '07:40'),
  TripHistoryStop(name: 'كوبري الساحل', order: 2),
  TripHistoryStop(name: 'موقف المنشية', order: 3, scheduledTime: '10:30'),
];

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ar'),
    theme: CaptainTheme.light(),
    home: child,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeTripHistoryRepository repository,
  TripHistoryItem? trip,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  captainGetIt.registerFactory<TripHistoryDetailCubit>(
    () => TripHistoryDetailCubit(GetTripStopsUseCase(repository)),
  );
  addTearDown(captainGetIt.reset);

  await tester.pumpWidget(_host(TripHistoryDetailPage(trip: trip ?? _trip())));
  await tester.pumpAndSettle();
}

// iPhone SE, a common mid-size phone, and a tall device.
const _sizes = <String, Size>{
  'small': Size(320, 568),
  'medium': Size(390, 844),
  'large': Size(430, 932),
};

void main() {
  for (final entry in _sizes.entries) {
    testWidgets('detail renders without overflow on ${entry.key}', (
      tester,
    ) async {
      await _pump(
        tester,
        repository: _FakeTripHistoryRepository(stops: _stops),
        size: entry.value,
      );

      expect(find.text('مسار الرحلة'), findsOneWidget);
      expect(find.text('4 محطات'), findsOneWidget);
      expect(find.text('موقف عبود'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the plate is on the page — the entity always carried it and the '
      'screen never showed it', (tester) async {
    await _pump(
      tester,
      repository: _FakeTripHistoryRepository(stops: _stops),
      trip: _trip(plate: 'ط ن ج 4821'),
    );

    expect(find.text('لوحة الترخيص'), findsOneWidget);
    expect(find.text('ط ن ج 4821'), findsOneWidget);
    expect(find.text('BUS-104'), findsOneWidget);
  });

  testWidgets('a trip with no recorded stops says so', (tester) async {
    await _pump(tester, repository: _FakeTripHistoryRepository());

    expect(find.text('لا توجد محطات مسجلة لهذه الرحلة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed stops fetch leaves the trip facts on screen', (
    tester,
  ) async {
    await _pump(
      tester,
      repository: _FakeTripHistoryRepository(
        failure: Exception('انقطع الاتصال'),
      ),
    );

    // The stops are one section of the page; losing them must not take the
    // journey and vehicle cards down with them.
    expect(find.text('المركبة'), findsOneWidget);
    expect(find.text('المغادرة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
