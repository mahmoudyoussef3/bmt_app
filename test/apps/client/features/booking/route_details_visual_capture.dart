/// Visual QA harness for the rewritten Route Details screen — the line the
/// rider commits to before the booking wizard asks anything else.
///
/// The screen's whole point is what it *leaves out* (fares, selectable
/// departures, commute packages, the operator badge — all of them decisions
/// the wizard owns), so the thing to check here is that what remains reads as
/// one calm page: map, identity, stations, timetable. None of that can be
/// judged from code.
///
/// Not a test of behaviour and deliberately not part of the suite's
/// assertions: run it with `--update-goldens` and look at the PNGs it writes
/// to `_captures/`.
///
///     flutter test test/apps/client/features/booking/route_details_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/transport_office.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_results_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_results_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/route_selection_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_stop_timeline.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

const _captureFont = 'CaptureArabic';

/// Stands in for the real cubit so the screen renders a fixed result instead
/// of reaching for Supabase.
class _StaticRouteResultsCubit extends Cubit<RouteResultsState>
    implements RouteResultsCubit {
  _StaticRouteResultsCubit(super.initialState);

  @override
  Future<void> load(BookingSearchQuery query) async {}

  @override
  void selectRoute(String id) {}

  @override
  void selectTrip(String id) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;

    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  testWidgets('the full page, Arabic, light', (tester) async {
    await _capture(tester, 'route_details_1_ar_light', dark: false);
  });

  testWidgets('the full page, Arabic, dark', (tester) async {
    await _capture(tester, 'route_details_2_ar_dark', dark: true);
  });

  testWidgets('the full page, English, light', (tester) async {
    await _capture(
      tester,
      'route_details_3_en_light',
      dark: false,
      locale: const Locale('en'),
      direction: TextDirection.ltr,
    );
  });

  testWidgets('a line whose operator published no stations or departures', (
    tester,
  ) async {
    await _capture(
      tester,
      'route_details_4_ar_bare',
      dark: false,
      routes: [_bareRoute()],
    );
  });

  testWidgets('the stations card alone, with mapped stations', (tester) async {
    await _captureStations(tester, 'route_details_5_ar_stations');
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Fixtures — the real Banha ↔ AUC corridor from the screenshots, with the
// mixed Arabic/Latin station names that make the direction line and the
// clocks worth looking at.
//
// Stops carry no coordinates on purpose. `EasyWayRouteMapView` pulls tiles and
// road geometry over the network and styles its attribution badge with a
// Google font; under the test binding all three are blocked, and the font's
// failure lands after the test body as an unhandled error. So the hero renders
// its documented no-coordinates fallback here, which still frames the card and
// both of its floating pills — the parts of it this harness is for.
// ─────────────────────────────────────────────────────────────────────────

const _office = TransportOffice(
  id: 'office-1',
  name: 'Dashboard Test',
  rating: 4,
  ratingsCount: 26,
);

RoutePointData _stop(
  String name,
  int order, {
  double? lat,
  double? lng,
  bool pickup = true,
  bool dropoff = true,
  String arrival = '',
  String departure = '',
}) {
  return RoutePointData(
    id: 'stop-$order',
    name: name,
    order: order,
    pickupAllowed: pickup,
    dropoffAllowed: dropoff,
    latitude: lat,
    longitude: lng,
    arrivalOffset: arrival,
    departureOffset: departure,
  );
}

RouteTripOptionData _trip({
  required String id,
  required String departure,
  required String arrival,
  required int seats,
  required String vehicle,
}) {
  return RouteTripOptionData(
    id: id,
    tripDate: _today,
    departureTime: departure,
    arrivalTime: arrival,
    availableSeats: seats,
    vehicleType: vehicle,
    price: 'EGP 100',
  );
}

String get _today {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

RouteOptionData _mainRoute() {
  return RouteOptionData(
    id: 'r-1',
    routeName: 'Banha - American University in Cairo (AUC) - New Cairo',
    pickup: 'American University in Cairo (AUC) - New Cairo',
    destination: 'Banha',
    distance: '86 كم',
    duration: '1 س 6 د',
    availableSeats: 14,
    startingPrice: 'EGP 100',
    priceRange: 'EGP 100 - 140',
    office: _office,
    points: [
      // Offsets are durations from the line's start, so the clocks a rider
      // reads are these plus the soonest departure (07:30).
      _stop(
        'American University in Cairo (AUC) - New Cairo',
        1,
        dropoff: false,
        arrival: '00:00',
        departure: '00:00',
      ),
      _stop('موقف السلام', 2, arrival: '00:22', departure: '00:25'),
      // A station the bus passes without waiting: one clock, not two.
      _stop('Police Academy', 3, arrival: '00:41', departure: '00:41'),
      _stop('Banha', 4, pickup: false, arrival: '01:06', departure: '01:06'),
    ],
    availableTrips: [
      _trip(
        id: 't-2',
        departure: '19:00:00',
        arrival: '20:06:00',
        seats: 14,
        vehicle: 'Coaster',
      ),
      _trip(
        id: 't-1',
        departure: '07:30:00',
        arrival: '08:36:00',
        seats: 3,
        vehicle: 'Hiace',
      ),
      _trip(
        id: 't-3',
        departure: '22:15:00',
        arrival: '23:20:00',
        seats: 11,
        vehicle: 'Coaster',
      ),
    ],
  );
}

/// A second line for the same search, so the alternatives card renders.
RouteOptionData _alternativeRoute() {
  return RouteOptionData(
    id: 'r-2',
    routeName: 'Banha - Nasr City express',
    pickup: 'Banha',
    destination: 'مدينة نصر',
    distance: '74 كم',
    duration: '58 د',
    availableSeats: 6,
    startingPrice: 'EGP 85',
    priceRange: 'EGP 85 - 110',
    office: _office,
    matchQuality: RouteMatchQuality.partial,
    points: [_stop('Banha', 1), _stop('مدينة نصر', 2)],
    availableTrips: const [],
  );
}

/// The degraded case: a line the operator created but never fleshed out.
RouteOptionData _bareRoute() {
  return const RouteOptionData(
    id: 'r-3',
    routeName: 'خط قيد الإعداد',
    pickup: 'طنطا',
    destination: 'المنصورة',
    distance: '',
    duration: '',
    availableSeats: 0,
    startingPrice: 'Price pending',
    priceRange: '',
    availableTrips: [],
  );
}

/// The stations card on its own, with coordinates on every stop so the
/// per-station "open in maps" action renders.
///
/// It is captured apart from the page because coordinates are exactly what
/// makes the hero map reach for tiles and road geometry, which the test
/// binding blocks — see the fixture note above. The card is the same widget
/// the page embeds.
Future<void> _captureStations(WidgetTester tester, String name) async {
  tester.view.physicalSize = const Size(420, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _themeWithHostFont(dark: false),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RouteStopTimeline(
                points: _mappedStops(),
                referenceDeparture: '07:30:00',
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// The same corridor with the coordinates the operator mapped.
List<RoutePointData> _mappedStops() => [
  _stop(
    'American University in Cairo (AUC) - New Cairo',
    1,
    dropoff: false,
    lat: 30.0199,
    lng: 31.4993,
    arrival: '00:00',
    departure: '00:00',
  ),
  _stop(
    'موقف السلام',
    2,
    lat: 30.1281,
    lng: 31.3742,
    arrival: '00:22',
    departure: '00:25',
  ),
  _stop('Police Academy', 3, arrival: '00:41', departure: '00:41'),
  _stop(
    'Banha',
    4,
    pickup: false,
    lat: 30.4599,
    lng: 31.1837,
    arrival: '01:06',
    departure: '01:06',
  ),
];

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required bool dark,
  Locale locale = const Locale('ar'),
  TextDirection direction = TextDirection.rtl,
  List<RouteOptionData>? routes,
  double width = 420,
  double height = 1900,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final results = routes ?? [_mainRoute(), _alternativeRoute()];
  final cubit = _StaticRouteResultsCubit(RouteResultsLoaded(routes: results));
  addTearDown(cubit.close);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _themeWithHostFont(dark: dark),
      home: Directionality(
        textDirection: direction,
        child: RepaintBoundary(
          key: key,
          child: BlocProvider<RouteResultsCubit>.value(
            value: cubit,
            child: RouteSelectionScreen(
              query: const BookingSearchQuery(
                pickup: 'American University in Cairo (AUC) - New Cairo',
                destination: 'Banha',
                date: '2026-08-26',
                time: '19:00:00',
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// The client theme builds its text theme through `GoogleFonts.cairo…`, which
/// the test binding's blocked network turns into a hard failure. This
/// hand-builds a [ThemeData] carrying only what the client design system
/// actually reads off it — the brightness (which is what selects the real
/// `ClientPalette`) — with the host Arabic font substituted for Cairo. The
/// palette and every `ClientColors.…For(context)` value are the real ones;
/// only the glyphs differ.
ThemeData _themeWithHostFont({required bool dark}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: _captureFont),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: _captureFont),
  );
}
