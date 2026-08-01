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

Widget _host(Widget child, {double scale = 1.0}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ar'),
    theme: CaptainTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeTripHistoryRepository repository,
  TripHistoryItem? trip,
  Size size = const Size(390, 844),
  double scale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  captainGetIt.registerFactory<TripHistoryDetailCubit>(
    () => TripHistoryDetailCubit(GetTripStopsUseCase(repository)),
  );
  addTearDown(captainGetIt.reset);

  await tester.pumpWidget(
    _host(TripHistoryDetailPage(trip: trip ?? _trip()), scale: scale),
  );
  await tester.pumpAndSettle();
}

// iPhone SE, a common mid-size phone, and a tall device.
const _sizes = <String, Size>{
  'small': Size(320, 568),
  'medium': Size(390, 844),
  'large': Size(430, 932),
};

void main() {
  /// The route timeline stacks a marker, a stop name and a time on each row —
  /// an enlarged system font is what pushes those past the row width.
  for (final scale in [1.3, 1.6]) {
    testWidgets('detail holds at small @ textScale $scale', (tester) async {
      await _pump(
        tester,
        repository: _FakeTripHistoryRepository(stops: _stops),
        size: const Size(320, 568),
        scale: scale,
      );

      expect(tester.takeException(), isNull);
    });
  }

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

  /// The vehicle rows used to split themselves 50/50 — the label and the value
  /// each carried a flex, so the value was capped at half the card no matter
  /// how short its label was. A plate then lost its tail to an ellipsis with
  /// empty space sitting beside "لوحة الترخيص", and a truncated plate is a
  /// *different* plate, not a clipped word.
  group('label → value rows', () {
    testWidgets('values of different lengths share one trailing column', (
      tester,
    ) async {
      await _pump(
        tester,
        repository: _FakeTripHistoryRepository(stops: _stops),
      );

      // The app runs RTL, so a row's trailing edge is its **left** edge.
      final code = tester.getRect(find.text('BUS-104'));
      final plate = tester.getRect(find.text('ط ن ج 4821'));

      expect(
        plate.left,
        code.left,
        reason: 'a plate and a bus code must start at the same trailing edge',
      );
      // The two genuinely differ in length — otherwise the assertion above
      // would also hold for a layout that had gone back to fixed columns.
      expect(plate.width, isNot(code.width));
    });

    testWidgets('a long plate never runs over its label', (tester) async {
      await _pump(
        tester,
        repository: _FakeTripHistoryRepository(stops: _stops),
        // Longer than any plate the fleet issues, on the narrowest phone.
        trip: _trip(plate: 'ط ن ج 4821 مصر القاهرة الكبرى'),
        size: const Size(320, 568),
      );

      final label = tester.getRect(find.text('لوحة الترخيص'));
      final value = tester.getRect(find.text('ط ن ج 4821 مصر القاهرة الكبرى'));

      expect(value.right, lessThanOrEqualTo(label.left));
      expect(label.width, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('both section headings start from the same edge', (tester) async {
    // The page named one section from inside its own card and the other from
    // above it, so two adjacent blocks stated their titles in two different
    // places. Both now sit on the background, aligned with each other.
    await _pump(tester, repository: _FakeTripHistoryRepository(stops: _stops));

    expect(
      tester.getRect(find.text('المركبة')).right,
      tester.getRect(find.text('مسار الرحلة')).right,
    );
  });

  /// The card states a booked count, a boarded count and a bar, and used to
  /// leave the captain to work out whether that added up to a good trip.
  group('the trip states its own outcome', () {
    testWidgets('a shortfall is named', (tester) async {
      await _pump(
        tester,
        repository: _FakeTripHistoryRepository(stops: _stops),
        trip: _trip(boarded: 18),
      );

      expect(find.text('اكتملت الرحلة — لم يصعد راكبان'), findsOneWidget);
    });

    testWidgets('a full trip is stated as one', (tester) async {
      await _pump(
        tester,
        repository: _FakeTripHistoryRepository(stops: _stops),
        trip: _trip(boarded: 20),
      );

      expect(find.text('اكتملت الرحلة وصعد جميع الركاب'), findsOneWidget);
    });
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
