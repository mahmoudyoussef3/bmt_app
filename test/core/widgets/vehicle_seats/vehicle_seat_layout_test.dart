import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

/// The shared seat system's contract: one renderer draws every EWT cabin, the
/// physical layout and the seat states stay independent, and no business rule
/// gets in.

List<VehicleSeatData> _seatsFor(
  SeatLayoutBlueprint blueprint, {
  Map<int, SeatViewState> states = const {},
  Set<int> disabledTaps = const {},
  int extra = 0,
}) {
  return [
    for (var i = 0; i < blueprint.capacity + extra; i++)
      VehicleSeatData(
        id: 's$i',
        label: '${i + 1}'.padLeft(2, '0'),
        state: states[i] ?? SeatViewState.available,
        enabled: !disabledTaps.contains(i),
      ),
  ];
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(500, 1800),
  TextDirection direction = TextDirection.rtl,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Hiace cabin', () {
    testWidgets('draws every passenger seat and its driver area', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
      );

      expect(find.byType(VehicleSeat), findsNWidgets(14));
      // Two front positions belong to the driver area, and neither is a seat.
      expect(find.byType(VehicleSeatFixture), findsNWidgets(2));
      expect(find.text('سائق'), findsOneWidget);
      // The Hiace has no modelled passenger door.
      expect(find.byIcon(Icons.sensor_door_outlined), findsNothing);
    });

    testWidgets('orients the rider: front at the top, rear at the bottom', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
      );

      final front = tester.getCenter(find.text('مقدمة المركبة'));
      final rear = tester.getCenter(find.text('مؤخرة المركبة'));
      expect(front.dy, lessThan(rear.dy));
      // And the driver sits in the front half, not the back.
      expect(tester.getCenter(find.text('سائق')).dy, lessThan(rear.dy));
    });

    testWidgets('does not mirror under RTL — a cabin is a physical object', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
      );

      // Column 1 is the driver's side of a left-hand-drive vehicle; seat 01
      // sits across the aisle from it, in the last column.
      final driver = tester.getCenter(find.text('سائق'));
      final firstSeat = tester.getCenter(find.text('01'));
      expect(driver.dx, lessThan(firstSeat.dx));
    });
  });

  /// The physical drawing, measured off the rendered cabin rather than off the
  /// blueprint: a front compartment, four passenger rows, a rear row that is
  /// visibly wider, and one aisle running the length of the vehicle.
  ///
  /// These read seat positions from the widget tree, so they fail if the
  /// geometry regresses even when the blueprint is still correct.
  group('Hiace cabin geometry', () {
    Future<void> pumpHiace(WidgetTester tester) => _pump(
      tester,
      VehicleSeatLayout(
        blueprint: VehicleSeatLayouts.hiace,
        seats: _seatsFor(VehicleSeatLayouts.hiace),
      ),
    );

    Rect rectOf(WidgetTester tester, String label) =>
        tester.getRect(find.byKey(ValueKey('seat-s${int.parse(label) - 1}')));

    double xOf(WidgetTester tester, String label) =>
        rectOf(tester, label).center.dx;
    double yOf(WidgetTester tester, String label) =>
        rectOf(tester, label).center.dy;

    /// The cabin fixture (driver bench, door) carrying [label].
    Rect fixtureOf(WidgetTester tester, String label) => tester.getRect(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(VehicleSeatFixture),
      ),
    );

    testWidgets('the front cabin is a compartment, not the first row', (
      tester,
    ) async {
      await pumpHiace(tester);

      // The driver, the crew position and the one front passenger seat all sit
      // on the same line, ahead of every passenger row.
      final driver = fixtureOf(tester, 'سائق');
      final crew = fixtureOf(tester, 'A2');
      expect(driver.center.dy, closeTo(crew.center.dy, 0.5));
      expect(yOf(tester, '1'), closeTo(driver.center.dy, 0.5));
      expect(yOf(tester, '1'), lessThan(yOf(tester, '2')));

      // And it is *divided* from the passenger cabin: the step down to the
      // first passenger row is bigger than the step between passenger rows.
      final bulkheadGap = yOf(tester, '2') - yOf(tester, '1');
      final rowGap = yOf(tester, '5') - yOf(tester, '2');
      expect(
        bulkheadGap,
        greaterThan(rowGap),
        reason: 'the front cabin must be separated, not merely first',
      );
    });

    testWidgets('there are exactly four passenger rows', (tester) async {
      await pumpHiace(tester);

      final rows = <double>{};
      for (var seat = 2; seat <= 14; seat++) {
        rows.add((yOf(tester, '$seat') / 10).roundToDouble());
      }
      expect(rows, hasLength(4));
    });

    testWidgets('rows 1 to 3 are drawn 2 + aisle + 1', (tester) async {
      await pumpHiace(tester);

      for (final row in const [
        ['2', '3', '4'],
        ['5', '6', '7'],
        ['8', '9', '10'],
      ]) {
        final left = xOf(tester, row[0]);
        final middle = xOf(tester, row[1]);
        final window = xOf(tester, row[2]);

        expect(left, lessThan(middle));
        expect(middle, lessThan(window));
        expect(
          window - middle,
          greaterThan((middle - left) * 1.3),
          reason:
              'seats ${row[0]}/${row[1]} are a bank; ${row[2]} is across the '
              'aisle from them',
        );
      }
    });

    testWidgets('the rear row is one bench of four, side by side', (
      tester,
    ) async {
      await pumpHiace(tester);

      final bench = [
        for (final seat in const ['11', '12', '13', '14'])
          rectOf(tester, seat),
      ];

      // All four on one line.
      for (final seat in bench) {
        expect(seat.center.dy, closeTo(bench.first.center.dy, 0.5));
      }

      // Side by side, evenly: the run has no wider break in it, so no seat —
      // 14 least of all — reads as a single stranded across an aisle.
      final steps = [
        for (var i = 1; i < bench.length; i++)
          bench[i].center.dx - bench[i - 1].center.dx,
      ];
      for (final step in steps) {
        expect(step, greaterThan(0));
        expect(
          step,
          closeTo(steps.first, 0.5),
          reason: 'the bench must be evenly spaced end to end',
        );
      }

      // And nothing else is on that line.
      final rearY = bench.first.center.dy;
      expect(
        [
          for (var seat = 1; seat <= 14; seat++)
            if ((yOf(tester, '$seat') - rearY).abs() < 1) seat,
        ],
        [11, 12, 13, 14],
      );
    });

    testWidgets('the bench spans the cabin, wall to wall', (tester) async {
      await pumpHiace(tester);

      // It starts at the kerbside wall the rows in front start at and ends at
      // the window wall they end at — a bench, not a centred block of four.
      expect(rectOf(tester, '11').left, closeTo(rectOf(tester, '8').left, 0.5));
      expect(
        rectOf(tester, '14').right,
        closeTo(rectOf(tester, '10').right, 0.5),
      );

      // Fitting a fourth seat across costs the bench a little width — the
      // physical trade the vehicle makes where the aisle ends.
      expect(rectOf(tester, '11').width, lessThan(rectOf(tester, '8').width));
    });

    testWidgets('the column system holds from the front to the rear', (
      tester,
    ) async {
      await pumpHiace(tester);

      // Every seat in a column is drawn at the same x — that is what makes the
      // drawing a cabin rather than four independently centred rows. The bench
      // is not in the columns; it spans them, and is checked above.
      for (final column in const [
        ['2', '5', '8'],
        ['3', '6', '9'],
        ['1', '4', '7', '10'],
      ]) {
        final xs = [for (final seat in column) xOf(tester, seat)];
        for (final x in xs) {
          expect(x, closeTo(xs.first, 1), reason: 'column $column must align');
        }
      }
    });

    testWidgets('the aisle is one continuous lane, not a gap per row', (
      tester,
    ) async {
      await pumpHiace(tester);

      final lanes = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('cabin-aisle-'),
      );
      expect(
        lanes,
        findsOneWidget,
        reason: 'four stacked gaps would be four widgets, not one lane',
      );

      final aisle = tester.getRect(lanes);

      // It runs from the front of the passenger cabin down to the bench that
      // ends it — the walkway stops where the vehicle stops having one, not a
      // row early and not through the back seats.
      expect(aisle.top, lessThan(rectOf(tester, '2').top));
      expect(aisle.bottom, greaterThan(rectOf(tester, '8').bottom));
      expect(aisle.bottom, lessThanOrEqualTo(rectOf(tester, '11').top + 1));

      // And it stays between the seat banks the whole way: right of the
      // kerbside pair, left of the seats across from it.
      expect(aisle.left, greaterThanOrEqualTo(rectOf(tester, '9').right - 1));
      expect(aisle.right, lessThanOrEqualTo(rectOf(tester, '10').left + 1));
    });

    testWidgets('the walkway lines up with the front cabin walk-through', (
      tester,
    ) async {
      await pumpHiace(tester);

      final aisle = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'cabin-aisle-',
              ),
        ),
      );
      final crew = fixtureOf(tester, 'A2');
      final frontSeat = rectOf(tester, '1');

      // The gap the aisle opens into is the one between the driver bench and
      // the front passenger, so the vehicle has one walkable line end to end.
      expect(aisle.center.dx, greaterThan(crew.right));
      expect(aisle.center.dx, lessThan(frontSeat.left));
    });
  });

  group('Coaster cabin', () {
    testWidgets('draws 30 seats, the entrance door and the driver', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.coaster;
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
        size: const Size(500, 2600),
      );

      expect(find.byType(VehicleSeat), findsNWidgets(30));
      expect(find.byIcon(Icons.sensor_door_outlined), findsOneWidget);
      expect(find.text('سائق'), findsOneWidget);
    });

    testWidgets('is a different cabin from the Hiace, not a rescaled one', (
      tester,
    ) async {
      expect(
        VehicleSeatLayouts.coaster.rows.length,
        isNot(VehicleSeatLayouts.hiace.rows.length),
      );
      expect(
        VehicleSeatLayouts.coaster.capacity,
        isNot(VehicleSeatLayouts.hiace.capacity),
      );
    });

    testWidgets('the entrance sits behind the driver, never in front', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.coaster;
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
        size: const Size(500, 2600),
      );

      final driver = tester.getCenter(find.text('سائق'));
      final door = tester.getCenter(find.byIcon(Icons.sensor_door_outlined));
      expect(driver.dx, lessThan(door.dx));
    });
  });

  group('seat state', () {
    testWidgets('the same layout renders any mix of states', (tester) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(
          blueprint: blueprint,
          seats: _seatsFor(
            blueprint,
            states: {
              0: SeatViewState.selected,
              1: SeatViewState.occupied,
              2: SeatViewState.reserved,
              3: SeatViewState.disabled,
            },
          ),
        ),
      );

      // Layout is untouched by state: still fourteen seats in the same cabin.
      expect(find.byType(VehicleSeat), findsNWidgets(14));
      // Colour is never the only cue — each non-free state carries a glyph.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    });

    testWidgets('a free seat carries no glyph, so taken seats stand out', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
      );

      expect(find.byIcon(Icons.person_rounded), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.block_rounded), findsNothing);
    });

    testWidgets('a per-seat glyph override shades a state without a new one', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      final seats = _seatsFor(blueprint, states: {0: SeatViewState.occupied});
      await _pump(
        tester,
        VehicleSeatLayout(
          blueprint: blueprint,
          seats: [
            seats.first.copyWith(icon: Icons.card_membership_rounded),
            ...seats.skip(1),
          ],
        ),
      );

      expect(find.byIcon(Icons.card_membership_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsNothing);
    });
  });

  group('seat numbering', () {
    testWidgets('labels come from the data, never from the slot position', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(
          blueprint: blueprint,
          seats: [
            for (var i = 0; i < blueprint.capacity; i++)
              VehicleSeatData(
                id: 's$i',
                label: 'X${i + 1}',
                state: SeatViewState.available,
              ),
          ],
        ),
      );

      for (var i = 1; i <= 14; i++) {
        expect(find.text('X$i'), findsOneWidget);
      }
      // The renderer invented no numbering of its own.
      expect(find.text('1'), findsNothing);
    });
  });

  group('modes', () {
    testWidgets('preview and readOnly report nothing', (tester) async {
      final blueprint = VehicleSeatLayouts.hiace;
      final tapped = <String>[];

      for (final mode in [SeatLayoutMode.preview, SeatLayoutMode.readOnly]) {
        await _pump(
          tester,
          VehicleSeatLayout(
            blueprint: blueprint,
            seats: _seatsFor(blueprint),
            mode: mode,
            onSeatTap: (seat) => tapped.add(seat.id),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('seat-s0')));
        await tester.pump();
      }

      expect(tapped, isEmpty);
    });

    testWidgets('selection reports only the seats the parent enabled', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      final tapped = <String>[];
      await _pump(
        tester,
        VehicleSeatLayout(
          blueprint: blueprint,
          seats: _seatsFor(
            blueprint,
            states: {1: SeatViewState.occupied},
            disabledTaps: {1},
          ),
          mode: SeatLayoutMode.selection,
          onSeatTap: (seat) => tapped.add(seat.id),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('seat-s0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('seat-s1')));
      await tester.pump();

      // The widget applied no rule of its own — it reported what was enabled.
      expect(tapped, ['s0']);
    });

    testWidgets('management reports taken seats too', (tester) async {
      final blueprint = VehicleSeatLayouts.hiace;
      final tapped = <String>[];
      await _pump(
        tester,
        VehicleSeatLayout(
          blueprint: blueprint,
          seats: _seatsFor(blueprint, states: {1: SeatViewState.occupied}),
          mode: SeatLayoutMode.management,
          onSeatTap: (seat) => tapped.add(seat.id),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('seat-s1')));
      await tester.pump();

      expect(tapped, ['s1']);
    });
  });

  group('legend', () {
    testWidgets('is off unless the parent asks for it', (tester) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
      );
      expect(find.byType(VehicleSeatLegend), findsNothing);
    });

    testWidgets('lists only the states actually on the map', (tester) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(
          blueprint: blueprint,
          seats: _seatsFor(blueprint, states: {0: SeatViewState.occupied}),
          showLegend: true,
        ),
      );

      expect(find.byType(VehicleSeatLegend), findsOneWidget);
      expect(find.text('متاح'), findsOneWidget);
      expect(find.text('محجوز'), findsOneWidget);
      // Nothing on this map is reserved or withdrawn, so neither is explained.
      expect(find.text('قيد الحجز'), findsNothing);
      expect(find.text('غير متاح'), findsNothing);
    });
  });

  group('responsiveness', () {
    testWidgets('seats stay within their density bounds at any width', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;

      for (final width in [320.0, 600.0, 1400.0]) {
        await _pump(
          tester,
          VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
          size: Size(width, 1800),
        );
        final seat = tester.getSize(find.byKey(const ValueKey('seat-s0')));
        expect(
          seat.width,
          inInclusiveRange(
            SeatLayoutDensity.comfortable.minSeat,
            SeatLayoutDensity.comfortable.maxSeat,
          ),
          reason: 'seat must not shrink or stretch out of proportion @ $width',
        );
        expect(seat.width, seat.height);
      }
    });

    testWidgets('the vehicle never stretches to fill a desktop panel', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
        size: const Size(1600, 1800),
      );

      // The cabin is centred at its intrinsic width, well inside the viewport.
      final cabin = tester.getSize(find.byType(VehicleSeatLayout));
      final seat = tester.getSize(find.byKey(const ValueKey('seat-s0')));
      expect(seat.width, SeatLayoutDensity.comfortable.maxSeat);
      expect(cabin.width, lessThanOrEqualTo(1600));
    });

    testWidgets('compact density fits the same cabin into a card', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        SizedBox(
          width: 280,
          child: VehicleSeatLayout(
            blueprint: blueprint,
            seats: _seatsFor(blueprint),
            density: SeatLayoutDensity.compact,
          ),
        ),
      );

      final seat = tester.getSize(find.byKey(const ValueKey('seat-s0')));
      expect(
        seat.width,
        inInclusiveRange(
          SeatLayoutDensity.compact.minSeat,
          SeatLayoutDensity.compact.maxSeat,
        ),
      );
      // Same cabin, same seats — only the room they get changed.
      expect(find.byType(VehicleSeat), findsNWidgets(14));
    });
  });

  group('layout configuration', () {
    testWidgets('forType resolves the cabin from the vehicle type alone', (
      tester,
    ) async {
      await _pump(
        tester,
        VehicleSeatLayout.forType(
          type: VehicleType.hiace,
          seats: _seatsFor(VehicleSeatLayouts.hiace),
        ),
      );

      expect(find.byType(VehicleSeat), findsNWidgets(14));
      expect(find.text('سائق'), findsOneWidget);
    });

    testWidgets('a seat count the cabin disagrees with keeps the cabin', (
      tester,
    ) async {
      // Seven seats in a Hiace-typed vehicle. The vehicle is still a Hiace —
      // a stale `seat_configuration` does not get to redraw it as a grid — so
      // the seven seats fill the first seven places of the cabin and the rest
      // of the cabin stays bare floor.
      await _pump(
        tester,
        VehicleSeatLayout.forType(
          type: VehicleType.hiace,
          seats: [
            for (var i = 0; i < 7; i++)
              VehicleSeatData(
                id: 's$i',
                label: '${i + 1}',
                state: SeatViewState.available,
              ),
          ],
        ),
      );

      expect(find.byType(VehicleSeat), findsNWidgets(7));
      // The Hiace is still recognisably a Hiace.
      expect(find.text('سائق'), findsOneWidget);
      expect(find.text('A2'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'cabin-aisle-',
              ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a type with no cabin of its own is still drawn as stored', (
      tester,
    ) async {
      await _pump(
        tester,
        VehicleSeatLayout.forType(
          type: VehicleType.other,
          seats: [
            for (var i = 0; i < 7; i++)
              VehicleSeatData(
                id: 's$i',
                label: '${i + 1}',
                state: SeatViewState.available,
              ),
          ],
        ),
      );

      expect(find.byType(VehicleSeat), findsNWidgets(7));
    });

    testWidgets('seats beyond the cabin are listed, never dropped', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.hiace;
      await _pump(
        tester,
        VehicleSeatLayout(
          blueprint: blueprint,
          seats: _seatsFor(blueprint, extra: 3),
        ),
      );

      expect(find.byType(VehicleSeat), findsNWidgets(17));
      expect(find.textContaining('مقاعد إضافية'), findsOneWidget);
    });

    testWidgets('an empty cabin renders nothing rather than throwing', (
      tester,
    ) async {
      await _pump(
        tester,
        const VehicleSeatLayout(
          blueprint: SeatLayoutBlueprint(rows: [], capacity: 0, columns: 0),
          seats: [],
        ),
      );

      expect(find.byType(VehicleSeat), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a derived grid still gets its driver bench back', (
      tester,
    ) async {
      // The shape `SeatConfiguration.generateDefault` produces: the front-left
      // cell is empty because `trip_seats` holds no driver row.
      final blueprint = SeatLayoutBlueprint.fromSeatGrid([
        (row: 1, column: 2),
        (row: 1, column: 3),
        for (var i = 0; i < 6; i++) (row: (i ~/ 3) + 2, column: (i % 3) + 1),
      ]);
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
      );

      expect(find.text('سائق'), findsOneWidget);
      expect(
        tester.getCenter(find.text('سائق')).dx,
        lessThan(tester.getCenter(find.text('01')).dx),
      );
    });

    testWidgets('a blueprint that names its driver gains no second bench', (
      tester,
    ) async {
      final blueprint = VehicleSeatLayouts.coaster;
      await _pump(
        tester,
        VehicleSeatLayout(blueprint: blueprint, seats: _seatsFor(blueprint)),
        size: const Size(500, 2600),
      );

      expect(find.text('سائق'), findsOneWidget);
    });
  });

  group('one renderer', () {
    test('no app draws cabin slots of its own', () {
      // The guard that keeps this system from re-fragmenting. `SeatSlotKind` is
      // the vocabulary for placing a seat, an aisle, a driver bench or a door
      // in a cabin; the moment a feature reaches for it, that feature is
      // building a second seat renderer. Only the shared one may.
      final offenders = <String>[];
      for (final dir in ['lib/apps', 'lib/landing']) {
        final root = Directory(dir);
        if (!root.existsSync()) continue;
        for (final entity in root.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          if (entity.readAsStringSync().contains('SeatSlotKind')) {
            offenders.add(entity.path);
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'these files place cabin slots themselves instead of using '
            'VehicleSeatLayout: ${offenders.join(', ')}',
      );
    });

    test('the seat tile and the cabin renderer live in core, once each', () {
      final seatFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where(
            (f) => f.readAsStringSync().contains('class VehicleSeat extends'),
          )
          .map((f) => f.path)
          .toList();

      expect(seatFiles, ['lib/core/widgets/vehicle_seats/vehicle_seat.dart']);
    });
  });
}
