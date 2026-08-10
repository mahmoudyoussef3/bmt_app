// Temporary visual-verification harness (not a `_test.dart`, so `flutter test`
// does not collect it). Run explicitly:
//
//   flutter test test/core/widgets/vehicle_seats/hiace_visual_capture.dart
//
// Writes PNGs of the Hiace cabin in each seat-state case so the geometry can be
// inspected by eye rather than trusted because it compiles.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

/// flutter_test ships an empty font manifest, so every glyph — Arabic text and
/// Material icons alike — renders as a blank box unless real fonts are loaded.
/// A capture drawn without them cannot answer "can a rider tell these five
/// states apart", which is the whole point of looking at it.
Future<void> _loadFonts() async {
  // `flutter_tester` lives under <flutter>/bin/cache/artifacts/engine/<arch>/,
  // and the Material icon font under <flutter>/bin/cache/artifacts/
  // material_fonts/ — so walk up until that directory turns up.
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

List<VehicleSeatData> _seats({
  required int count,
  Map<int, SeatViewState> states = const {},
  SeatViewState fallback = SeatViewState.available,
}) {
  return [
    for (var i = 0; i < count; i++)
      VehicleSeatData(
        id: 's$i',
        label: '${i + 1}'.padLeft(2, '0'),
        state: states[i] ?? fallback,
      ),
  ];
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  Widget child, {
  double width = 430,
  Brightness brightness = Brightness.light,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: brightness, fontFamily: 'Arial'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: brightness == Brightness.dark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFFFFFF),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(width: width, child: child),
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
  testWidgets('hiace cabin captures', (tester) async {
    await tester.binding.setSurfaceSize(const Size(560, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _capture(
      tester,
      'hiace_1_available',
      VehicleSeatLayout(
        blueprint: VehicleSeatLayouts.hiace,
        seats: _seats(count: 14),
        showLegend: true,
        caption: 'Toyota Hiace • ١٤ مقعد',
      ),
    );

    await _capture(
      tester,
      'hiace_2_mixed',
      VehicleSeatLayout(
        blueprint: VehicleSeatLayouts.hiace,
        seats: _seats(
          count: 14,
          states: {
            1: SeatViewState.occupied,
            2: SeatViewState.reserved,
            4: SeatViewState.occupied,
            7: SeatViewState.occupied,
            9: SeatViewState.reserved,
            12: SeatViewState.disabled,
          },
        ),
        showLegend: true,
        mode: SeatLayoutMode.selection,
      ),
    );

    await _capture(
      tester,
      'hiace_3_selected',
      VehicleSeatLayout(
        blueprint: VehicleSeatLayouts.hiace,
        seats: _seats(
          count: 14,
          states: {
            0: SeatViewState.selected,
            5: SeatViewState.selected,
            10: SeatViewState.selected,
            13: SeatViewState.selected,
            3: SeatViewState.occupied,
            8: SeatViewState.occupied,
          },
        ),
        showLegend: true,
        mode: SeatLayoutMode.selection,
      ),
    );

    await _capture(
      tester,
      'hiace_4_full',
      VehicleSeatLayout(
        blueprint: VehicleSeatLayouts.hiace,
        seats: _seats(count: 14, fallback: SeatViewState.occupied),
        showLegend: true,
      ),
    );

    await _capture(
      tester,
      'hiace_5_compact',
      SizedBox(
        width: 320,
        child: VehicleSeatLayout(
          blueprint: VehicleSeatLayouts.hiace,
          seats: _seats(
            count: 14,
            states: {
              0: SeatViewState.occupied,
              3: SeatViewState.reserved,
              11: SeatViewState.disabled,
            },
          ),
          density: SeatLayoutDensity.compact,
          maxWidth: 320,
          caption: 'Toyota Hiace - هايس',
        ),
      ),
      width: 320,
    );

    await _capture(
      tester,
      'hiace_6_dark',
      VehicleSeatLayout(
        blueprint: VehicleSeatLayouts.hiace,
        seats: _seats(
          count: 14,
          states: {
            2: SeatViewState.selected,
            6: SeatViewState.occupied,
            9: SeatViewState.reserved,
          },
        ),
        showLegend: true,
      ),
      brightness: Brightness.dark,
    );

    await _capture(
      tester,
      'coaster_reference',
      VehicleSeatLayout(
        blueprint: VehicleSeatLayouts.coaster,
        seats: _seats(
          count: 30,
          states: {0: SeatViewState.occupied, 5: SeatViewState.selected},
        ),
        density: SeatLayoutDensity.compact,
      ),
      width: 430,
    );
  });
}
