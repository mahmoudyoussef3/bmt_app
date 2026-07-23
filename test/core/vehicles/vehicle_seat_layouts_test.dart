import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/vehicles/vehicles.dart';

/// The shared contract both apps rest on: a vehicle type resolves to exactly
/// one cabin, and that cabin is only used when it fits the trip's real seats.
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

  group('Hiace blueprint', () {
    final hiace = VehicleSeatLayouts.hiace;

    test('is 14 seats over 5 rows, as it has always been', () {
      expect(hiace.capacity, 14);
      expect(hiace.rows, hasLength(5));
      expect(hiace.columns, 4);
    });

    test('keeps the cabin the client already draws: 1 + 3x3 + 4', () {
      final seatsPerRow = [
        for (final row in hiace.rows) row.where((s) => s.isSeat).length,
      ];
      expect(seatsPerRow, [1, 3, 3, 3, 4]);
    });

    test('has a driver bench up front and an aisle in the body rows', () {
      final front = hiace.rows.first;
      expect(front.where((s) => s.kind == SeatSlotKind.driver), hasLength(2));
      expect(hiace.driverLabels, ['A1', 'A2']);
      expect(
        hiace.rows[1].any((s) => s.kind == SeatSlotKind.aisle),
        isTrue,
      );
    });

    test('numbers seats in the order the apps sort seat data', () {
      expect(
        [for (final slot in hiace.seatSlots) slot.seatNumber],
        List.generate(14, (i) => i + 1),
      );
    });

    test('persists the seat labels trip_seats has always carried', () {
      final passengers = hiace
          .seatDefinitions()
          .where((d) => !d.isDriver)
          .toList();
      expect(passengers, hasLength(14));
      expect([for (final p in passengers) p.label], [
        for (var i = 1; i <= 14; i++) '$i',
      ]);
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

    test('legacy Hiace coordinates still resolve to the Hiace cabin', () {
      // What `SeatConfiguration.generateDefault(14)` wrote before blueprints:
      // one seat beside the driver, then rows of three.
      final legacy = <({int row, int column})>[
        (row: 1, column: 3),
        for (var seat = 2; seat <= 14; seat++)
          (row: ((seat - 2) ~/ 3) + 2, column: ((seat - 2) % 3) + 1),
      ];
      expect(legacy, hasLength(14));
      expect(
        VehicleSeatLayouts.resolve(type: VehicleType.hiace, seats: legacy),
        same(VehicleSeatLayouts.hiace),
      );
    });

    test(
      'a Coaster still carrying 14 seats falls back to its own seat grid',
      () {
        // The placeholder row in production. Drawing a 30-slot Coaster frame
        // around 14 seats would be worse than drawing the seats as stored.
        final resolved = VehicleSeatLayouts.resolve(
          type: VehicleType.coaster,
          seats: gridOf(VehicleSeatLayouts.hiace),
        );
        expect(resolved, isNot(same(VehicleSeatLayouts.coaster)));
        expect(resolved.capacity, 14);
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
      final resolved = VehicleSeatLayouts.resolveRaw(
        vehicleType: 'Coaster',
        seats: const [],
      );
      expect(resolved.capacity, 0);
      expect(resolved.rows, isEmpty);
    });
  });
}
