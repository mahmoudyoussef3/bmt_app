// Temporary visual-verification harness (not a `_test.dart`, so `flutter test`
// does not collect it). Run explicitly:
//
//   flutter test test/apps/client/features/home/home_trip_card_visual_capture.dart --update-goldens
//
// Writes PNGs of the Home departure card in every state it ships in, so the
// layout can be inspected by eye rather than trusted because it compiles.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trips_list.dart';

/// flutter_test ships an empty font manifest, so every glyph — Arabic text and
/// Material icons alike — renders as a blank box unless real fonts are loaded.
Future<void> _loadFonts() async {
  var dir = File(Platform.resolvedExecutable).parent;
  var icons = '';
  for (var i = 0; i < 6 && icons.isEmpty; i++) {
    final candidate = File(
      '${dir.path}/material_fonts/MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) icons = candidate.path;
    dir = dir.parent;
  }

  final fonts = <String, String>{
    'Arial': '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
    'Roboto': '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
    if (icons.isNotEmpty) 'MaterialIcons': icons,
  };

  for (final entry in fonts.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) continue;
    final loader = FontLoader(entry.key)
      ..addFont(
        file.readAsBytes().then(
          (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
        ),
      );
    await loader.load();
  }
}

UpcomingTripData _trip({
  String routeName = 'Cairo – Tanta Express',
  String officeName = 'EasyWay Transport',
  String pickup = 'El-Marg, QH, Egypt',
  String destination = 'American University in Cairo (AUC)',
  String departureTime = '08:30:00',
  String tripDate = '',
  String duration = '1h 19m',
  String price = 'EGP 100',
  int seatsLeft = 14,
  bool isLive = false,
  HomeBookingStatus? bookedStatus,
  int bookedSeats = 0,
}) {
  return UpcomingTripData(
    tripId: 't1',
    routeId: 'r1',
    routeName: routeName,
    officeName: officeName,
    pickup: pickup,
    destination: destination,
    tripDate: tripDate,
    departureTime: departureTime,
    duration: duration,
    price: price,
    seatsLeft: seatsLeft,
    isLive: isLive,
    bookedStatus: bookedStatus,
    bookedSeats: bookedSeats,
  );
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  List<UpcomingTripData> trips, {
  double width = 375,
  Locale locale = const Locale('en'),
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // Captures are pumped back to back; without this the light case that
      // follows a dark one is photographed mid-lerp between the two themes.
      themeAnimationDuration: Duration.zero,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness, fontFamily: 'Arial'),
      home: Builder(
        builder: (context) => Directionality(
          textDirection: direction,
          child: Scaffold(
            backgroundColor: ClientColors.backgroundFor(context),
            body: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: ClientColors.backgroundFor(context),
                  child: SizedBox(
                    width: width,
                    child: CustomScrollView(
                      shrinkWrap: true,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: HomeUpcomingTripsList(
                            trips: trips,
                            onBook: (_) {},
                            onBrowseRoutes: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

void main() {
  setUpAll(_loadFonts);

  // One test: each `testWidgets` re-enters the binding and the capture run
  // stalls between cases, so the whole set is rendered in a single body.
  testWidgets('home departure card captures', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _capture(tester, 'trip_1_board_en', [
      _trip(tripDate: DateTime.now().toIso8601String().split('T').first),
      _trip(
        routeName: 'Cairo – Mansoura',
        officeName: 'Delta Lines',
        departureTime: '11:15:00',
        pickup: 'Ramses Station',
        destination: 'Mansoura Terminal',
        duration: '2h 05m',
        price: 'EGP 145',
        seatsLeft: 3,
      ),
    ]);

    await _capture(tester, 'trip_2_states_en', [
      _trip(bookedStatus: HomeBookingStatus.underReview, bookedSeats: 2),
      _trip(
        routeName: 'Cairo – Alexandria',
        departureTime: '07:00:00',
        isLive: true,
        seatsLeft: 0,
        price: 'EGP 180',
      ),
    ]);

    await _capture(
      tester,
      'trip_3_board_ar',
      [
        _trip(
          routeName: 'القاهرة – طنطا السريع',
          officeName: 'إيزي واي للنقل',
          pickup: 'محطة رمسيس، القاهرة',
          destination: 'الجامعة الأمريكية بالقاهرة (الفرع الجديد)',
          price: '١٠٠ ج.م',
          duration: 'ساعة و١٩ د',
          tripDate: DateTime.now().toIso8601String().split('T').first,
        ),
        _trip(
          routeName: 'القاهرة – المنصورة',
          officeName: 'خطوط الدلتا',
          departureTime: '11:15:00',
          pickup: 'موقف عبود',
          destination: 'محطة المنصورة',
          seatsLeft: 3,
          price: '١٤٥ ج.م',
          duration: 'ساعتان',
          bookedStatus: HomeBookingStatus.confirmed,
          bookedSeats: 1,
        ),
      ],
      locale: const Locale('ar'),
      direction: TextDirection.rtl,
    );

    await _capture(tester, 'trip_4_dark', [
      _trip(bookedStatus: HomeBookingStatus.onBoard, bookedSeats: 1),
      _trip(
        routeName: 'Cairo – Suez',
        departureTime: '',
        officeName: '',
        duration: '',
        price: '',
        seatsLeft: 9,
      ),
    ], brightness: Brightness.dark);

    // The smallest phone the app ships to, with the longest strings on it.
    await _capture(tester, 'trip_5_narrow', [
      _trip(
        routeName: 'Cairo Ramses – Tanta El-Mahatta Express Service',
        bookedStatus: HomeBookingStatus.underReview,
        bookedSeats: 3,
        seatsLeft: 2,
      ),
    ], width: 320);

    // More departures than the board prints, so the "view all" appears.
    await _capture(tester, 'trip_6_capped', [
      for (var i = 0; i < 7; i++)
        _trip(routeName: 'Route ${i + 1}', departureTime: '0${i + 2}:00:00'),
    ]);
  });
}
