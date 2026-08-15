// Temporary visual-verification harness (not a `_test.dart`, so `flutter test`
// does not collect it). Run explicitly:
//
//   flutter test test/apps/client/features/trips/trip_detail_sections_visual_capture.dart \
//     --update-goldens
//
// Writes PNGs of the crew (captain + bus) and payment cards across the states
// that change their shape — a booking awaiting approval, a paid trip under way,
// a finished trip inviting a rating — in Arabic RTL, English LTR, and dark mode,
// so the density can be judged by eye.
//
// Vehicle photos resolve to the placeholder here: flutter_test answers every
// network image with a 400, which is exactly the fallback path worth seeing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_detail_sections.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

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

List<TripSeat> _hiaceSeats({Set<int> occupied = const {}, int? mine}) {
  final definitions = VehicleSeatLayouts.hiace
      .seatDefinitions()
      .where((d) => !d.isDriver)
      .toList();
  return [
    for (var i = 0; i < definitions.length; i++)
      TripSeat(
        label: definitions[i].label,
        number: i + 1,
        row: definitions[i].row,
        column: definitions[i].column,
        state: mine == i + 1
            ? TripSeatState.mine
            : occupied.contains(i + 1)
            ? TripSeatState.occupied
            : TripSeatState.available,
      ),
  ];
}

TripData _trip({
  required TripStatus status,
  required PaymentStatus paymentStatus,
  BookingState bookingState = BookingState.confirmed,
  required bool arabic,
  List<TripSeat> seatMap = const [],
  List<String> seats = const ['A3'],
  double rating = 4.8,
  int ratingCount = 126,
  List<String> vehicleImageUrls = const [
    'https://example.test/bus-1.png',
    'https://example.test/bus-2.png',
    'https://example.test/bus-3.png',
  ],
}) {
  return TripData(
    id: 'b1',
    reference: 'BMT-4821',
    status: status,
    pickup: arabic ? 'القاهرة' : 'Cairo',
    destination: arabic ? 'المنصورة' : 'Mansoura',
    dateLabel: arabic ? 'اليوم' : 'Today',
    timeLabel: '08:00',
    driverName: arabic ? 'محمود عبد الرحمن' : 'Mahmoud Abdelrahman',
    driverPhone: '01000000000',
    driverInitials: arabic ? 'م ع' : 'MA',
    driverRating: rating,
    driverRatingCount: ratingCount,
    vehicleName: arabic ? 'تويوتا هايس 2022' : 'Toyota Hiace 2022',
    vehicleType: 'Hiace',
    vehicleId: 'v1',
    vehiclePlate: 'ب ن ط 4821',
    vehicleImageUrls: vehicleImageUrls,
    seats: seats,
    seatMap: seatMap,
    paymentStatus: paymentStatus,
    bookingState: bookingState,
    fare: arabic ? '١٢٠ ج.م' : 'EGP 120',
  );
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required TripData trip,
  required Locale locale,
  Brightness brightness = Brightness.light,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Not `ClientTheme.light()`: it builds its text theme from google_fonts,
      // which tries to fetch Outfit over a network the test binding blocks.
      theme: ThemeData(brightness: brightness, fontFamily: 'Arial'),
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: ClientColors.backgroundFor(context),
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: key,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: TripDetailSections(trip: trip),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('trip detail section captures', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const arabic = Locale('ar');
    const english = Locale('en');

    await _capture(
      tester,
      'sections_1_ar_reserved_pending',
      locale: arabic,
      trip: _trip(
        arabic: true,
        status: TripStatus.upcoming,
        paymentStatus: PaymentStatus.underReview,
        bookingState: BookingState.reserved,
        seatMap: _hiaceSeats(occupied: const {2, 5, 9}, mine: 4),
      ),
    );

    await _capture(
      tester,
      'sections_2_ar_in_progress_paid',
      locale: arabic,
      trip: _trip(
        arabic: true,
        status: TripStatus.inProgress,
        paymentStatus: PaymentStatus.paid,
        seatMap: _hiaceSeats(occupied: const {1, 2, 3, 6, 7, 11}, mine: 8),
        seats: const ['A3', 'A4'],
      ),
    );

    await _capture(
      tester,
      'sections_3_ar_completed',
      locale: arabic,
      trip: _trip(
        arabic: true,
        status: TripStatus.completed,
        paymentStatus: PaymentStatus.paid,
        bookingState: BookingState.completed,
        seatMap: _hiaceSeats(occupied: const {1, 2, 3}, mine: 5),
        rating: 0,
        ratingCount: 0,
      ),
    );

    // A thin fleet record: no photos of the bus, so the row must not offer a
    // gallery — and an unrated captain, who must not read as zero stars.
    await _capture(
      tester,
      'sections_4_ar_no_photos',
      locale: arabic,
      trip: _trip(
        arabic: true,
        status: TripStatus.upcoming,
        paymentStatus: PaymentStatus.pending,
        bookingState: BookingState.reserved,
        seats: const [],
        rating: 0,
        ratingCount: 0,
        vehicleImageUrls: const [],
      ),
    );

    await _capture(
      tester,
      'sections_5_ar_dark',
      locale: arabic,
      brightness: Brightness.dark,
      trip: _trip(
        arabic: true,
        status: TripStatus.inProgress,
        paymentStatus: PaymentStatus.paid,
        seatMap: _hiaceSeats(occupied: const {2, 5, 9}, mine: 4),
      ),
    );

    await _capture(
      tester,
      'sections_6_en_in_progress_paid',
      locale: english,
      trip: _trip(
        arabic: false,
        status: TripStatus.inProgress,
        paymentStatus: PaymentStatus.paid,
        seatMap: _hiaceSeats(occupied: const {2, 5, 9}, mine: 4),
      ),
    );

    // The narrowest phone the client app targets, with the longest strings the
    // rows can carry — where a name, a rating, a badge and a plate compete for
    // one line.
    await tester.binding.setSurfaceSize(const Size(320, 2200));
    await _capture(
      tester,
      'sections_7_ar_narrow',
      locale: arabic,
      trip: _trip(
        arabic: true,
        status: TripStatus.inProgress,
        paymentStatus: PaymentStatus.underReview,
        seatMap: _hiaceSeats(occupied: const {2, 5, 9}, mine: 4),
        seats: const ['A3', 'A4', 'B1'],
      ),
    );
  });
}
