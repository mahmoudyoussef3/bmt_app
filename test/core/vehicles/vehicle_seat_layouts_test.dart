import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/vehicles/vehicles.dart';

/// The shared contract both apps rest on: a vehicle type resolves to exactly
/// one cabin, and it keeps that cabin — the physical layout of a vehicle is a
/// property of the vehicle, not of how many seat rows happen to be configured.
void main() {
  group('VehicleTypeParser', () {
    test('maps the values already stored in the database', () {
      expect(VehicleTypeParser.fromDatabase('Hiace'), VehicleType.hiace);
      expect(VehicleTypeParser.fromDatabase('Coaster'), VehicleType.coaster);
      expect(VehicleTypeParser.fromDatabase('H1'), VehicleType.h1);
      expect(VehicleTypeParser.fromDatabase('Sprinter'), VehicleType.sprinter);
    });

    test('tolerates casing, spacing and a brand prefix', () {
      expect(VehicleTypeParser.fromDatabase('hiace'), VehicleType.hiace);
      expect(VehicleTypeParser.fromDatabase('Toyota Hiace'), VehicleType.hiace);
      expect(
        VehicleTypeParser.fromDatabase('toyota-coaster'),
        VehicleType.coaster,
      );
      expect(VehicleTypeParser.fromDatabase('كوستر'), VehicleType.coaster);
    });

    test('falls back to other rather than guessing a layout', () {
      expect(VehicleTypeParser.fromDatabase(null), VehicleType.other);
      expect(VehicleTypeParser.fromDatabase(''), VehicleType.other);
      expect(VehicleTypeParser.fromDatabase('  '), VehicleType.other);
      expect(VehicleTypeParser.fromDatabase('Karsan e-ATA'), VehicleType.other);
    });

    test('round-trips through the value persisted to the database', () {
      for (final type in VehicleType.values) {
        expect(VehicleTypeParser.fromDatabase(type.dbValue), type);
      }
    });
  });

  /// The physical Toyota Hiace: a front cabin, then four passenger rows of
  /// which the last is wider than the rest. These tests describe the *shape* of
  /// the vehicle rather than its seat count, because a seat count is the one
  /// thing about a cabin that can be right while the cabin is wrong.
  group('Hiace blueprint', () {
    final hiace = VehicleSeatLayouts.hiace;

    /// The seats of [row], split into the bank before the aisle and the bank
    /// after it — the `2 + 1` / `2 + 2` reading, straight off the geometry.
    (List<int>, List<int>) banks(List<SeatSlot> row) {
      final aisle = row.indexWhere((s) => s.kind == SeatSlotKind.aisle);
      return (
        [
          for (final slot in row)
            if (slot.isSeat && (aisle < 0 || slot.column < row[aisle].column))
              slot.column,
        ],
        [
          for (final slot in row)
            if (slot.isSeat && aisle >= 0 && slot.column > row[aisle].column)
              slot.column,
        ],
      );
    }

    group('front cabin', () {
      test('is a compartment of its own, ahead of the passenger cabin', () {
        expect(hiace.frontCabinRows, 1);
        expect(hiace.passengerCabinRows, hasLength(4));
        expect(
          hiace.rows.length,
          hiace.frontCabinRows + hiace.passengerCabinRows.length,
        );
      });

      test('holds two driver positions and one bookable front seat', () {
        final front = hiace.rows.first;
        expect(
          front
              .where((s) => s.kind == SeatSlotKind.driver)
              .map((s) => s.column),
          [1, 2],
          reason: 'driver at the wheel, crew position beside them',
        );
        expect(
          front.where((s) => s.isSeat).map((s) => s.column),
          [4],
          reason: 'the front passenger sits by the right-hand door',
        );
        expect(hiace.driverLabels, ['A1', 'A2']);
      });

      test('keeps the driver out of the passenger cabin entirely', () {
        for (final row in hiace.passengerCabinRows) {
          expect(
            row.where((s) => s.kind == SeatSlotKind.driver),
            isEmpty,
            reason: 'a driver position may only exist in the front cabin',
          );
        }
      });

      test('never sells a driver position', () {
        final drivers = hiace.rows
            .expand((row) => row)
            .where((s) => s.kind == SeatSlotKind.driver);
        expect(drivers.every((s) => !s.isSeat && s.seatNumber == 0), isTrue);
        expect(hiace.capacity, hiace.seatSlots.length);
      });
    });

    group('passenger rows', () {
      test('there are exactly four of them', () {
        expect(hiace.passengerCabinRows, hasLength(4));
      });

      test('rows 1 to 3 are 2 + aisle + 1', () {
        for (var i = 0; i < 3; i++) {
          final (left, right) = banks(hiace.passengerCabinRows[i]);
          expect(left, [1, 2], reason: 'row ${i + 1}: two seats by the kerb');
          expect(right, [4], reason: 'row ${i + 1}: one seat by the window');
        }
      });

      test('the rear row is a bench of four, not a 2 + 1 row', () {
        final rear = hiace.passengerCabinRows.last;

        // Four seats and nothing else — no walkway runs through a bench, which
        // is exactly what makes it one.
        expect(rear.every((slot) => slot.isSeat), isTrue);
        expect(rear.where((slot) => slot.isSeat), hasLength(4));
        expect(rear.any((slot) => slot.kind == SeatSlotKind.aisle), isFalse);
        expect(hiace.benchRows, {4});

        // The four sit side by side across the cabin: consecutive columns, no
        // gap anywhere in the run, and none of them left on its own.
        expect(rear.map((slot) => slot.column), [1, 2, 3, 4]);

        // And it is wider than the rows in front of it — that is the whole
        // point of the bench.
        expect(
          rear.where((slot) => slot.isSeat).length,
          greaterThan(
            hiace.passengerCabinRows.first.where((slot) => slot.isSeat).length,
          ),
        );
      });

      test('only the rear row is a bench', () {
        for (var i = 0; i < hiace.rows.length - 1; i++) {
          expect(
            hiace.benchRows.contains(i),
            isFalse,
            reason: 'row $i has a walkway and must stay on the seat grid',
          );
        }
      });

      test('the cabin reads 1 + 3 + 3 + 3 + 4 front to back', () {
        expect(hiace.seatsPerRow, [1, 3, 3, 3, 4]);
      });

      test('every row is anchored to the same two walls', () {
        for (final row in hiace.rows) {
          expect(row.first.column, 1);
          expect(row.last.column, 4);
          expect(row.first.isWindow, isTrue);
          expect(row.last.isWindow, isTrue);
        }
      });
    });

    group('the aisle', () {
      test('is one column for the whole length of the vehicle', () {
        expect(
          hiace.aisleColumns,
          {3},
          reason: 'a single walkway column, not a gap re-invented per row',
        );
      });

      test('runs unbroken from the bulkhead to the rear bench', () {
        // Every row with a walkway is walkable at the same column, with no row
        // in between breaking the run.
        for (var row = 1; row <= 3; row++) {
          expect(
            hiace.rows[row].singleWhere((s) => s.column == 3).kind,
            SeatSlotKind.aisle,
            reason: 'passenger row $row must be walkable at column 3',
          );
        }
        // And it ends where the vehicle stops having one: at the bench.
        expect(hiace.benchRows, {hiace.rows.length - 1});
      });

      test('is never interrupted by a seat, a driver or a door', () {
        final benches = hiace.benchRows;
        final atThree = [
          for (var r = 0; r < hiace.rows.length; r++)
            if (!benches.contains(r))
              ...hiace.rows[r].where((s) => s.column == 3),
        ];
        expect(atThree.any((s) => s.isSeat), isFalse);
        expect(atThree.any((s) => s.kind == SeatSlotKind.driver), isFalse);
        expect(atThree.any((s) => s.kind == SeatSlotKind.door), isFalse);
      });

      test('opens onto the front cabin rather than starting mid-vehicle', () {
        // The walk-through between the front seats is column 3 as well, so the
        // renderer can run the lane straight up to the bulkhead.
        expect(hiace.rows.first[2].isGap, isTrue);
      });
    });

    group('seat data, not the blueprint, owns the numbers', () {
      test('slots are numbered in the order the apps sort seat data', () {
        expect([
          for (final slot in hiace.seatSlots) slot.seatNumber,
        ], List.generate(14, (i) => i + 1));
      });

      test('the capacity the database already carries is unchanged', () {
        expect(hiace.capacity, 14);
      });

      test('persists the seat labels trip_seats has always carried', () {
        final passengers = hiace
            .seatDefinitions()
            .where((d) => !d.isDriver)
            .toList();
        expect(passengers, hasLength(14));
        expect(
          [for (final p in passengers) p.label],
          [for (var i = 1; i <= 14; i++) '$i'],
        );
      });

      test('no two seats share a cabin position', () {
        expect({
          for (final slot in hiace.seatSlots) '${slot.row}:${slot.column}',
        }, hasLength(14));
      });

      test('stores the coordinates production already carries', () {
        // The reason this cabin needs no data migration: every `Hiace`-typed
        // vehicle in the database was generated from exactly these positions.
        // If this list ever has to change, the operator is owed a migration —
        // see docs/architecture/VEHICLE_SEAT_BLUEPRINTS.md.
        final passengers = hiace
            .seatDefinitions()
            .where((d) => !d.isDriver)
            .toList();
        expect(
          [for (final p in passengers) '${p.label}@${p.row},${p.column}'],
          [
            '1@1,4',
            '2@2,1', '3@2,2', '4@2,4',
            '5@3,1', '6@3,2', '7@3,4',
            '8@4,1', '9@4,2', '10@4,4',
            '11@5,1', '12@5,2', '13@5,3', '14@5,4',
          ],
        );
      });
    });
  });

  group('Coaster blueprint', () {
    final coaster = VehicleSeatLayouts.coaster;

    test('is 30 seats over 8 rows in a 2+2 arrangement', () {
      expect(coaster.capacity, 30);
      expect(coaster.rows, hasLength(8));
      expect(coaster.columns, 5);
    });

    test('seats per row: 1 beside the door, six 2+2 rows, a 5-seat bench', () {
      final seatsPerRow = [
        for (final row in coaster.rows) row.where((s) => s.isSeat).length,
      ];
      expect(seatsPerRow, [1, 4, 4, 4, 4, 4, 4, 5]);
    });

    test('shows the driver, the entrance door and a centre aisle', () {
      final front = coaster.rows.first;
      expect(front.where((s) => s.kind == SeatSlotKind.driver), hasLength(1));
      expect(front.where((s) => s.kind == SeatSlotKind.door), hasLength(1));
      expect(
        coaster.rows[1].where((s) => s.kind == SeatSlotKind.aisle),
        hasLength(1),
      );
    });

    test('marks the outermost seats of each row as window seats', () {
      final bodyRow = coaster.rows[1];
      expect(bodyRow.first.isWindow, isTrue);
      expect(bodyRow.last.isWindow, isTrue);
      expect(bodyRow[1].isWindow, isFalse);
    });

    test('differs from the Hiace cabin', () {
      expect(coaster.capacity, isNot(VehicleSeatLayouts.hiace.capacity));
      expect(coaster.rows.length, isNot(VehicleSeatLayouts.hiace.rows.length));
    });

    test('persists 30 uniquely numbered passenger seats', () {
      final passengers = coaster
          .seatDefinitions()
          .where((d) => !d.isDriver)
          .toList();
      expect(passengers, hasLength(30));
      expect({for (final p in passengers) p.label}, hasLength(30));
      expect(
        {for (final p in passengers) '${p.row}:${p.column}'},
        hasLength(30),
        reason: 'no two seats may share a cabin position',
      );
    });
  });

  group('blueprintFor / capacityFor', () {
    test('modelled types own their capacity', () {
      expect(VehicleSeatLayouts.capacityFor(VehicleType.hiace), 14);
      expect(VehicleSeatLayouts.capacityFor(VehicleType.coaster), 30);
    });

    test('unmodelled types leave capacity to the operator', () {
      expect(VehicleSeatLayouts.capacityFor(VehicleType.sprinter), isNull);
      expect(VehicleSeatLayouts.capacityFor(VehicleType.h1), isNull);
      expect(VehicleSeatLayouts.capacityFor(VehicleType.other), isNull);
      expect(VehicleSeatLayouts.blueprintFor(VehicleType.other), isNull);
    });
  });

  group('resolve', () {
    List<({int row, int column})> gridOf(SeatLayoutBlueprint blueprint) => [
      for (final definition in blueprint.seatDefinitions())
        if (!definition.isDriver)
          (row: definition.row, column: definition.column),
    ];

    test('a Hiace trip with 14 seats gets the Hiace cabin', () {
      final resolved = VehicleSeatLayouts.resolve(
        type: VehicleType.hiace,
        seats: gridOf(VehicleSeatLayouts.hiace),
      );
      expect(resolved, same(VehicleSeatLayouts.hiace));
    });

    test('a Coaster trip with 30 seats gets the Coaster cabin', () {
      final resolved = VehicleSeatLayouts.resolve(
        type: VehicleType.coaster,
        seats: gridOf(VehicleSeatLayouts.coaster),
      );
      expect(resolved, same(VehicleSeatLayouts.coaster));
      expect(resolved, isNot(same(VehicleSeatLayouts.hiace)));
    });

    test('a seat count that disagrees never costs a vehicle its cabin', () {
      // This used to fall back to a grid derived from the seat coordinates,
      // which meant one stale `seat_configuration` erased a vehicle's visual
      // identity in every app at once. A modelled vehicle is that vehicle
      // whatever its seat rows say; the mismatch is shown by the renderer
      // (bare slots, an overflow list) instead of by redrawing the van.
      final short = VehicleSeatLayouts.resolve(
        type: VehicleType.hiace,
        seats: gridOf(VehicleSeatLayouts.hiace).take(9).toList(),
      );
      expect(short, same(VehicleSeatLayouts.hiace));

      // The Coaster placeholder row in production: still a Coaster.
      final placeholder = VehicleSeatLayouts.resolve(
        type: VehicleType.coaster,
        seats: gridOf(VehicleSeatLayouts.hiace),
      );
      expect(placeholder, same(VehicleSeatLayouts.coaster));
    });

    test(
      'coordinates the blueprint disagrees with do not change the cabin',
      () {
        // Seats are poured into the cabin in reading order, so a vehicle saved
        // under the pre-blueprint coordinates still draws the same Hiace.
        final legacy = <({int row, int column})>[
          (row: 1, column: 3),
          for (var seat = 2; seat <= 14; seat++)
            (row: ((seat - 2) ~/ 3) + 2, column: ((seat - 2) % 3) + 1),
        ];
        expect(
          VehicleSeatLayouts.resolve(type: VehicleType.hiace, seats: legacy),
          same(VehicleSeatLayouts.hiace),
        );
      },
    );

    test('an unknown type is drawn from its seat data, never guessed', () {
      final resolved = VehicleSeatLayouts.resolveRaw(
        vehicleType: 'Karsan e-ATA',
        seats: const [
          (row: 1, column: 1),
          (row: 1, column: 2),
          (row: 2, column: 1),
          (row: 2, column: 2),
        ],
      );
      expect(resolved.capacity, 4);
      expect(resolved.rows, hasLength(2));
      expect(resolved.columns, 2);
    });

    test('holes in a derived grid stay empty rather than shifting seats', () {
      final resolved = VehicleSeatLayouts.resolveRaw(
        vehicleType: null,
        seats: const [
          (row: 1, column: 1),
          (row: 1, column: 3),
          (row: 2, column: 2),
        ],
      );
      expect(resolved.capacity, 3);
      expect(resolved.rows[0][1].isSeat, isFalse);
      expect(resolved.rows[0][2].isSeat, isTrue);
    });

    test('unusable coordinates degrade to a packed grid, not an empty map', () {
      // Rows written as 0 by an older mapper.
      final resolved = VehicleSeatLayouts.resolveRaw(
        vehicleType: 'Sprinter',
        seats: const [
          (row: 0, column: 0),
          (row: 0, column: 0),
          (row: 0, column: 0),
        ],
      );
      expect(resolved.capacity, 3);
    });

    test('no seats resolves to an empty cabin without throwing', () {
      // The one case a modelled type still yields on: with no seat data there
      // is nothing to place, and drawing a full Coaster would claim thirty
      // seats the trip does not have.
      final resolved = VehicleSeatLayouts.resolveRaw(
        vehicleType: 'Coaster',
        seats: const [],
      );
      expect(resolved.capacity, 0);
      expect(resolved.rows, isEmpty);
    });
  });
}
