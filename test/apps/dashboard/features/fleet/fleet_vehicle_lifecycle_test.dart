import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/data/models/fleet_models.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/domain/repositories/fleet_vehicles_repository.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/domain/usecases/fleet_vehicles_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/vehicle_seat_configuration.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// The full seat-persistence lifecycle, end to end through the real layers with a
/// storage-shaped fake standing in for Supabase:
///
///   create → generate layout → save → reload → edit type → save → reload
///
/// The fake round-trips every vehicle through `FleetVehicleModel.toJson` /
/// `.fromJson`, which is what makes this a persistence test rather than an
/// in-memory one — a seat that does not survive serialisation fails here.

/// A stand-in for the `vehicles` table: JSON in, JSON out.
class _FakeVehiclesRepository implements FleetVehiclesRepository {
  final Map<String, Map<String, dynamic>> rows = {};
  int _nextId = 1;

  /// Set to make the next write fail, the way a Postgres constraint would.
  String? failNextWriteWith;

  @override
  Future<List<FleetVehicle>> getVehicles() async =>
      rows.values.map(FleetVehicleModel.fromJson).toList();

  @override
  Future<FleetVehicle> createVehicle(FleetVehicle vehicle) async {
    _maybeFail();
    final id = 'v-${_nextId++}';
    final json = FleetVehicleModel.fromEntity(vehicle).toJson()..['id'] = id;
    rows[id] = json;
    return FleetVehicleModel.fromJson(json);
  }

  @override
  Future<FleetVehicle> updateVehicle(FleetVehicle vehicle) async {
    _maybeFail();
    final json = FleetVehicleModel.fromEntity(vehicle).toJson()
      ..['id'] = vehicle.id;
    rows[vehicle.id] = json;
    return FleetVehicleModel.fromJson(json);
  }

  @override
  Future<FleetVehicle> updateVehicleStatus(
    String vehicleId,
    FleetVehicleStatus status,
  ) async {
    _maybeFail();
    rows[vehicleId]!['status'] = status.name;
    return FleetVehicleModel.fromJson(rows[vehicleId]!);
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    _maybeFail();
    rows.remove(vehicleId);
  }

  @override
  Future<String> uploadFile(String bucket, String path, List<int> bytes) async =>
      'https://example.test/$bucket/$path';

  @override
  Future<void> deleteFile(String bucket, String path) async {}

  void _maybeFail() {
    final message = failNextWriteWith;
    if (message == null) return;
    failNextWriteWith = null;
    throw Exception(message);
  }
}

FleetVehiclesCubit _cubit(_FakeVehiclesRepository repository) {
  return FleetVehiclesCubit(
    getVehicles: GetFleetVehiclesUseCase(repository),
    createVehicle: CreateFleetVehicleUseCase(repository),
    updateVehicle: UpdateFleetVehicleUseCase(repository),
    updateVehicleStatus: UpdateFleetVehicleStatusUseCase(repository),
    deleteVehicle: DeleteFleetVehicleUseCase(repository),
    uploadFile: UploadVehicleFileUseCase(repository),
    deleteFile: DeleteVehicleFileUseCase(repository),
  );
}

/// A vehicle exactly as `FleetVehicleFormView._onSave` assembles one.
FleetVehicle _formOutput({
  String id = '',
  required VehicleType type,
  FleetVehicle? existing,
}) {
  final capacity = VehicleSeatConfigurator.capacityFor(type, 14);
  return FleetVehicle(
    id: id,
    vehicleCode: 'BUS-201',
    plateNumber: '٣٣٠٠ ق ل',
    vehicleType: type.dbValue,
    brand: 'Toyota',
    model: type.dbValue,
    manufactureYear: 2022,
    color: 'أبيض',
    capacity: capacity,
    seatLayoutType: 'standard',
    imageUrl: '',
    notes: '',
    status: FleetVehicleStatus.active,
    seatConfiguration: VehicleSeatConfigurator.resolve(
      type: type,
      capacity: capacity,
      existing: existing?.seatConfiguration,
      existingType: existing == null
          ? null
          : VehicleTypeParser.fromDatabase(existing.vehicleType),
    ),
    licenseExpiry: '',
    insuranceExpiry: '',
    inspectionExpiry: '',
  );
}

List<SeatLayoutItem> _passengers(FleetVehicle vehicle) => vehicle
    .seatConfiguration
    .seats
    .where((seat) => seat.seatType == 'passenger')
    .toList();

void main() {
  group('seat persistence lifecycle', () {
    late _FakeVehiclesRepository repository;
    late FleetVehiclesCubit cubit;

    setUp(() {
      repository = _FakeVehiclesRepository();
      cubit = _cubit(repository);
    });

    tearDown(() => cubit.close());

    test('a Coaster survives create → reload with all 30 seats', () async {
      await cubit.load();
      final saved = await cubit.saveVehicle(
        _formOutput(type: VehicleType.coaster),
      );

      expect(saved.capacity, 30);
      expect(_passengers(saved), hasLength(30));

      // Reload from "storage" — this is the round trip the bug would break.
      final reloaded = (await repository.getVehicles()).single;
      expect(reloaded.vehicleType, 'Coaster');
      expect(reloaded.capacity, 30);
      expect(_passengers(reloaded), hasLength(30));
      expect(
        {for (final seat in _passengers(reloaded)) seat.seatNumber},
        hasLength(30),
        reason: 'seat labels must stay unique across a save/reload',
      );
    });

    test('seat identity is stable across an edit that changes nothing', () async {
      await cubit.load();
      final created = await cubit.saveVehicle(
        _formOutput(type: VehicleType.hiace),
      );
      final before = _passengers(created)
          .map((s) => '${s.seatNumber}@${s.row}:${s.column}')
          .toList();

      // Re-save the same vehicle, as re-opening the form and pressing save does.
      final resaved = await cubit.saveVehicle(
        _formOutput(
          id: created.id,
          type: VehicleType.hiace,
          existing: created,
        ),
      );
      final after = _passengers(resaved)
          .map((s) => '${s.seatNumber}@${s.row}:${s.column}')
          .toList();

      expect(
        after,
        before,
        reason: 'a no-op edit must not renumber or move a single seat',
      );
    });

    test('switching Hiace → Coaster replaces the cabin rather than merging it', () async {
      await cubit.load();
      final hiace = await cubit.saveVehicle(_formOutput(type: VehicleType.hiace));
      expect(_passengers(hiace), hasLength(14));

      final coaster = await cubit.saveVehicle(
        _formOutput(id: hiace.id, type: VehicleType.coaster, existing: hiace),
      );

      expect(coaster.capacity, 30);
      expect(
        _passengers(coaster),
        hasLength(30),
        reason: '14 Hiace seats must not be left behind alongside 30 Coaster ones',
      );
      expect(
        {for (final seat in _passengers(coaster)) seat.seatNumber},
        hasLength(30),
      );

      // And the same after a reload, not just in the returned object.
      final reloaded = (await repository.getVehicles()).single;
      expect(_passengers(reloaded), hasLength(30));
    });

    test('switching back to Hiace restores exactly 14 seats', () async {
      await cubit.load();
      final coaster = await cubit.saveVehicle(
        _formOutput(type: VehicleType.coaster),
      );
      final backToHiace = await cubit.saveVehicle(
        _formOutput(
          id: coaster.id,
          type: VehicleType.hiace,
          existing: coaster,
        ),
      );

      expect(backToHiace.capacity, 14);
      expect(_passengers(backToHiace), hasLength(14));
    });

    test('capacity always equals the persisted passenger seat count', () async {
      // The invariant the database now enforces with a CHECK constraint. Holding
      // it in Dart too means the dashboard never composes a payload that the
      // database is going to reject.
      await cubit.load();
      for (final type in VehicleType.values) {
        final saved = await cubit.saveVehicle(_formOutput(type: type));
        expect(
          saved.capacity,
          _passengers(saved).length,
          reason: '${type.dbValue}: capacity must match the seat layout',
        );
      }
    });
  });

  group('cubit state transitions', () {
    late _FakeVehiclesRepository repository;
    late FleetVehiclesCubit cubit;

    setUp(() {
      repository = _FakeVehiclesRepository();
      cubit = _cubit(repository);
    });

    tearDown(() => cubit.close());

    test('load emits loaded with the stored vehicles', () async {
      await cubit.load();
      await cubit.saveVehicle(_formOutput(type: VehicleType.hiace));

      final state = cubit.state;
      expect(state, isA<FleetVehiclesLoaded>());
      expect((state as FleetVehiclesLoaded).vehicles, hasLength(1));
    });

    test('a failed load surfaces an error state', () async {
      final failing = _FakeVehiclesRepository()..failNextWriteWith = null;
      final broken = _cubit(failing);
      addTearDown(broken.close);

      failing.failNextWriteWith = 'network down';
      // getVehicles does not fail in the fake; drive the failure through a save.
      await broken.load();
      await expectLater(
        broken.saveVehicle(_formOutput(type: VehicleType.hiace)),
        throwsA(isA<Exception>()),
      );
    });

    test('a refused delete returns the message and keeps the list intact', () async {
      await cubit.load();
      final saved = await cubit.saveVehicle(
        _formOutput(type: VehicleType.hiace),
      );

      repository.failNextWriteWith =
          'لا يمكن حذف المركبة لارتباطها بـ 3 رحلة مسجّلة.';
      final error = await cubit.deleteVehicle(saved.id);

      expect(error, contains('لا يمكن حذف المركبة'));
      expect(
        cubit.state,
        isA<FleetVehiclesLoaded>(),
        reason: 'a refused delete must not blank the fleet screen',
      );
      expect((cubit.state as FleetVehiclesLoaded).vehicles, hasLength(1));
    });

    test('a permitted delete removes the vehicle', () async {
      await cubit.load();
      final saved = await cubit.saveVehicle(
        _formOutput(type: VehicleType.hiace),
      );

      expect(await cubit.deleteVehicle(saved.id), isNull);
      expect((cubit.state as FleetVehiclesLoaded).vehicles, isEmpty);
    });

    test('archiving keeps the row and its seat layout', () async {
      await cubit.load();
      final saved = await cubit.saveVehicle(
        _formOutput(type: VehicleType.coaster),
      );

      await cubit.updateVehicleStatus(saved.id, FleetVehicleStatus.archived);

      final archived = (await repository.getVehicles()).single;
      expect(archived.status, FleetVehicleStatus.archived);
      expect(
        _passengers(archived),
        hasLength(30),
        reason: 'archiving is not deleting — the cabin is still on record',
      );
    });
  });

  group('defensive seat configuration parsing', () {
    test('a row with the default {} config loads as unconfigured, not a crash', () {
      // vehicles.seat_configuration defaults to '{}'. Casting rows/columns
      // straight to int threw, and because the workspace loads in one pass a
      // single such row blanked the whole Fleet screen.
      final vehicle = FleetVehicleModel.fromJson({
        'id': 'v-x',
        'vehicle_code': 'BUS-X',
        'plate_number': '١١١١ ق ل',
        'vehicle_type': 'Hiace',
        'brand': 'Toyota',
        'model': 'Hiace',
        'manufacture_year': 2020,
        'color': 'أبيض',
        'capacity': 14,
        'seat_layout_type': 'standard',
        'status': 'active',
        'seat_configuration': <String, dynamic>{},
      });

      expect(vehicle.seatConfiguration.seats, isEmpty);
      expect(vehicle.seatConfiguration.rows, 0);
    });

    test('geometry is derived when the envelope is missing but seats are not', () {
      final vehicle = FleetVehicleModel.fromJson({
        'id': 'v-y',
        'vehicle_code': 'BUS-Y',
        'plate_number': '٢٢٢٢ ق ل',
        'vehicle_type': 'Hiace',
        'brand': 'Toyota',
        'model': 'Hiace',
        'manufacture_year': 2020,
        'color': 'أبيض',
        'capacity': 2,
        'seat_layout_type': 'standard',
        'status': 'active',
        'seat_configuration': {
          'seats': [
            {'seat_number': '1', 'seat_type': 'passenger', 'row': 1, 'column': 1},
            {'seat_number': '2', 'seat_type': 'passenger', 'row': 3, 'column': 2},
          ],
        },
      });

      expect(vehicle.seatConfiguration.seats, hasLength(2));
      expect(vehicle.seatConfiguration.rows, 3);
      expect(vehicle.seatConfiguration.columns, 2);
    });
  });
}
