import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/data/models/fleet_models.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/vehicle_seat_configuration.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// The Owner Dashboard half of the contract: picking a vehicle type decides the
/// capacity and the seats, switching type replaces them outright, and what is
/// persisted is what the Client App will draw.
void main() {
  int passengerCount(SeatConfiguration config) =>
      config.seats.where((s) => s.seatType == 'passenger').length;

  group('capacity follows the selected vehicle type', () {
    test('Hiace selects 14 seats', () {
      expect(VehicleSeatConfigurator.fixedCapacityFor(VehicleType.hiace), 14);
      expect(VehicleSeatConfigurator.capacityFor(VehicleType.hiace, 99), 14);
    });

    test('Toyota Coaster selects 30 seats', () {
      expect(VehicleSeatConfigurator.fixedCapacityFor(VehicleType.coaster), 30);
      expect(VehicleSeatConfigurator.capacityFor(VehicleType.coaster, 99), 30);
    });

    test('a type without a blueprint keeps the operator’s number', () {
      expect(VehicleSeatConfigurator.fixedCapacityFor(VehicleType.h1), isNull);
      expect(VehicleSeatConfigurator.capacityFor(VehicleType.h1, 11), 11);
    });

    test('every modelled type is offered in the form', () {
      expect(
        VehicleSeatConfigurator.typeLabels.keys,
        containsAll(VehicleType.values),
      );
    });
  });

  group('seat configuration generated per type', () {
    test('Hiace generates the 14-seat cabin', () {
      final config = VehicleSeatConfigurator.resolve(
        type: VehicleType.hiace,
        capacity: 14,
      );
      expect(passengerCount(config), 14);
      expect(config.rows, 5);
      expect(config.columns, 4);
      expect(config.seats.any((s) => s.seatType == 'driver'), isTrue);
    });

    test('Coaster generates the 30-seat cabin', () {
      final config = VehicleSeatConfigurator.resolve(
        type: VehicleType.coaster,
        capacity: 30,
      );
      expect(passengerCount(config), 30);
      expect(config.rows, 8);
      expect(config.columns, 5);
    });

    test('generation is free of duplicate seats', () {
      for (final type in [VehicleType.hiace, VehicleType.coaster]) {
        final config = VehicleSeatConfigurator.resolve(
          type: type,
          capacity: VehicleSeatConfigurator.fixedCapacityFor(type)!,
        );
        final passengers = config.seats.where((s) => s.seatType == 'passenger');
        expect(
          {for (final s in passengers) s.seatNumber},
          hasLength(passengers.length),
          reason: '$type must not repeat a seat number',
        );
        expect(
          {for (final s in config.seats) '${s.row}:${s.column}'},
          hasLength(config.seats.length),
          reason: '$type must not put two seats in one position',
        );
      }
    });

    test('an unmodelled type still uses the plain generated grid', () {
      final config = VehicleSeatConfigurator.resolve(
        type: VehicleType.h1,
        capacity: 11,
      );
      expect(passengerCount(config), 11);
    });
  });

  group('switching vehicle type', () {
    test('Hiace to Coaster replaces the seats, never merges them', () {
      final hiace = VehicleSeatConfigurator.resolve(
        type: VehicleType.hiace,
        capacity: 14,
      );

      final switched = VehicleSeatConfigurator.resolve(
        type: VehicleType.coaster,
        capacity: 30,
        existing: hiace,
        existingType: VehicleType.hiace,
      );

      expect(passengerCount(switched), 30);
      expect(switched.rows, 8);
      expect(
        switched.seats.length,
        VehicleSeatLayouts.coaster.seatDefinitions().length,
        reason: 'no Hiace seats may survive the switch',
      );
    });

    test('Coaster to Hiace replaces the seats too', () {
      final coaster = VehicleSeatConfigurator.resolve(
        type: VehicleType.coaster,
        capacity: 30,
      );

      final switched = VehicleSeatConfigurator.resolve(
        type: VehicleType.hiace,
        capacity: 14,
        existing: coaster,
        existingType: VehicleType.coaster,
      );

      expect(passengerCount(switched), 14);
      expect(switched.rows, 5);
    });

    test('switching an unmodelled type regenerates instead of reusing', () {
      final sprinter = VehicleSeatConfigurator.resolve(
        type: VehicleType.sprinter,
        capacity: 16,
      );

      final switched = VehicleSeatConfigurator.resolve(
        type: VehicleType.h1,
        capacity: 16,
        existing: sprinter,
        existingType: VehicleType.sprinter,
      );

      expect(passengerCount(switched), 16);
      expect(identical(switched, sprinter), isFalse);
    });

    test('an unchanged unmodelled vehicle keeps its stored configuration', () {
      final existing = SeatConfiguration.generateDefault(16);
      final resolved = VehicleSeatConfigurator.resolve(
        type: VehicleType.h1,
        capacity: 16,
        existing: existing,
        existingType: VehicleType.h1,
      );
      expect(identical(resolved, existing), isTrue);
    });
  });

  group('creating and editing vehicles', () {
    FleetVehicleModel vehicle({
      required VehicleType type,
      String id = '',
      SeatConfiguration? seatConfiguration,
    }) {
      final capacity = VehicleSeatConfigurator.capacityFor(type, 14);
      return FleetVehicleModel(
        id: id,
        vehicleCode: 'BUS-500',
        plateNumber: '٥٥٥٥ ق ل',
        vehicleType: type.dbValue,
        brand: 'Toyota',
        model: type.dbValue,
        manufactureYear: 2023,
        color: 'أبيض',
        capacity: capacity,
        seatLayoutType: 'standard',
        imageUrl: '',
        notes: '',
        status: FleetVehicleStatus.active,
        seatConfiguration:
            seatConfiguration ??
            VehicleSeatConfigurator.resolve(type: type, capacity: capacity),
        licenseExpiry: '',
        insuranceExpiry: '',
        inspectionExpiry: '',
      );
    }

    test('creating a Hiace persists 14 seats and the Hiace type', () {
      final json = vehicle(type: VehicleType.hiace).toJson();
      final seats = (json['seat_configuration'] as Map)['seats'] as List;

      expect(json['vehicle_type'], 'Hiace');
      expect(json['capacity'], 14);
      expect(seats.where((s) => s['seat_type'] == 'passenger'), hasLength(14));
    });

    test('creating a Coaster persists 30 seats and the Coaster type', () {
      final json = vehicle(type: VehicleType.coaster).toJson();
      final config = json['seat_configuration'] as Map;
      final seats = config['seats'] as List;

      expect(json['vehicle_type'], 'Coaster');
      expect(json['capacity'], 30);
      expect(seats.where((s) => s['seat_type'] == 'passenger'), hasLength(30));
      expect(config['rows'], 8);
      expect(config['columns'], 5);
    });

    test('the door is layout-only and is never persisted as a seat', () {
      final json = vehicle(type: VehicleType.coaster).toJson();
      final seats = (json['seat_configuration'] as Map)['seats'] as List;

      // A door persisted as a seat would become a bookable phantom seat when
      // the trip is created, because trip creation keeps every passenger row.
      expect(
        seats.where((s) => s['seat_type'] == 'passenger'),
        hasLength(VehicleSeatLayouts.coaster.capacity),
      );
      expect(
        seats.every(
          (s) =>
              const {'passenger', 'driver', 'empty'}.contains(s['seat_type']),
        ),
        isTrue,
      );
    });

    test('editing an existing Coaster keeps its 30 seats', () {
      final saved = vehicle(type: VehicleType.coaster, id: 'v-1');
      final reloaded = FleetVehicleModel.fromJson({
        ...saved.toJson(),
        'id': 'v-1',
      });

      final reSaved = VehicleSeatConfigurator.resolve(
        type: VehicleTypeParser.fromDatabase(reloaded.vehicleType),
        capacity: reloaded.capacity,
        existing: reloaded.seatConfiguration,
        existingType: VehicleTypeParser.fromDatabase(reloaded.vehicleType),
      );

      expect(reloaded.capacity, 30);
      expect(passengerCount(reloaded.seatConfiguration), 30);
      expect(passengerCount(reSaved), 30);
    });

    test('editing an existing Hiace keeps its 14 seats', () {
      final saved = vehicle(type: VehicleType.hiace, id: 'v-2');
      final reloaded = FleetVehicleModel.fromJson({
        ...saved.toJson(),
        'id': 'v-2',
      });

      expect(reloaded.vehicleType, 'Hiace');
      expect(reloaded.capacity, 14);
      expect(passengerCount(reloaded.seatConfiguration), 14);
    });

    test('a persisted configuration survives a round trip unchanged', () {
      final saved = vehicle(type: VehicleType.coaster, id: 'v-3');
      final reloaded = FleetVehicleModel.fromJson({
        ...saved.toJson(),
        'id': 'v-3',
      });

      expect(
        reloaded.seatConfiguration.toJson(),
        saved.seatConfiguration.toJson(),
      );
    });
  });
}
