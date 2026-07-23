import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_item.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_state.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/pages/trip_history_page.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/utils/trip_history_filters.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// The history tab is a dense Arabic layout — a route name, a clock at each end
/// of the trip, a boarding line and a scrolling row of counted filter chips, all
/// laid out from an RTL direction it inherits rather than declares. That is pure
/// layout, so a pump at real screen sizes is what actually proves it fits; the
/// analyzer cannot see a RenderFlex overflow.
///
/// Note these assertions are deliberately conservative: `flutter_test` swaps in
/// a test font whose glyphs are far wider than Cairo's, so Arabic strings
/// measure much longer here than on a device. Passing therefore proves the
/// layout holds with room to spare, but a failure is not automatically a
/// user-visible bug — check the real font before contorting a layout to satisfy
/// this file.
class _StubTripHistoryCubit extends Cubit<TripHistoryState>
    implements TripHistoryCubit {
  _StubTripHistoryCubit(super.initialState);

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
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TripHistoryItem _trip({
  String id = 't1',
  String route = 'القاهرة - الإسكندرية الطريق الصحراوي',
  int boarded = 18,
}) {
  final departure = DateTime(2026, 7, 16, 7, 5);
  return TripHistoryItem(
    id: id,
    route: route,
    tripDate: departure,
    departureTime: departure,
    arrivalTime: departure.add(const Duration(hours: 3, minutes: 25)),
    passengerCount: 20,
    boardedCount: boarded,
    vehicleNumber: 'BUS-104',
    plateNumber: 'ط ن ج 4821',
  );
}

TripHistoryLoaded _loaded({
  List<TripHistoryItem>? trips,
  String query = '',
  TripHistoryDateFilter dateFilter = TripHistoryDateFilter.all,
}) {
  final items = trips ?? [_trip(), _trip(id: 't2', route: 'القاهرة - أسوان')];
  return TripHistoryLoaded(
    totalTrips: items.length,
    totalPassengers: items.fold(0, (sum, t) => sum + t.boardedCount),
    groups: groupTripHistoryByPeriod(items),
    matchCount: items.length,
    filterCounts: countTripsByDateFilter(items),
    query: query,
    dateFilter: dateFilter,
  );
}

Widget _host(Widget child, {double scale = 1.0}) {
  return MaterialApp(
    // Mirrors CaptainApp: the delegates are what load the app's `ar` date
    // symbols that CaptainFormats depends on, and the locale is what puts the
    // whole tab in the RTL direction its rows read their order from.
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

// iPhone SE, a common mid-size phone, and a tall device.
const _sizes = <String, Size>{
  'small': Size(320, 568),
  'medium': Size(390, 844),
  'large': Size(430, 932),
};

Future<void> _pump(
  WidgetTester tester,
  TripHistoryState state, {
  double scale = 1.0,
}) async {
  await tester.pumpWidget(
    _host(
      BlocProvider<TripHistoryCubit>(
        create: (_) => _StubTripHistoryCubit(state),
        child: const TripHistoryPage(),
      ),
      scale: scale,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  /// The history rows pack a route, a date, a time strip and a boarding bar
  /// into one card, so an enlarged system font is the case most likely to
  /// break them — and the smallest phone is where it breaks first.
  for (final scale in [1.3, 1.6]) {
    testWidgets('history holds at small @ textScale $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, _loaded(), scale: scale);

      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in _sizes.entries) {
    testWidgets('history renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, _loaded());

      expect(find.text('سجل الرحلات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filtered history renders its results line on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(
        tester,
        _loaded(query: 'أسوان', dateFilter: TripHistoryDateFilter.thisWeek),
      );

      expect(find.text('مسح الفلاتر'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a trip with no passengers reports it instead of dividing by '
      'zero', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final empty = TripHistoryItem(
      id: 't1',
      route: 'القاهرة - أسوان',
      tripDate: DateTime(2026, 7, 16, 7, 5),
      departureTime: DateTime(2026, 7, 16, 7, 5),
      arrivalTime: DateTime(2026, 7, 16, 10, 30),
      passengerCount: 0,
      boardedCount: 0,
      vehicleNumber: '',
      plateNumber: '',
    );

    await _pump(tester, _loaded(trips: [empty]));

    expect(find.text('لا ركاب مسجلين'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the two clocks stay in their own runs, so RTL cannot reorder '
      'the trip against itself', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _loaded(trips: [_trip()]));

    // Each clock is its own Text — the departure can never be re-ordered to
    // read as the arrival, which is what the old '07:05 → 10:30' string did
    // once bidi got hold of it.
    expect(find.text('07:05'), findsOneWidget);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('المغادرة'), findsOneWidget);
    expect(find.text('الوصول'), findsOneWidget);
  });

  testWidgets('an empty history says so rather than showing an empty list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _loaded(trips: []));

    expect(find.text('لا توجد رحلات مكتملة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
