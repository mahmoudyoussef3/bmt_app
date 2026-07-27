import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/vehicle_seat_configuration.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// The two readings a fleet row shows — what the bus is doing, and what state its
/// record is in — and specifically what happens when they disagree.

FleetVehicle _vehicle({
  String id = 'v-1',
  FleetVehicleStatus status = FleetVehicleStatus.active,
}) {
  return FleetVehicle(
    id: id,
    vehicleCode: 'BUS-$id',
    plateNumber: '١٢٣٤ أ ب ج',
    vehicleType: VehicleType.hiace.dbValue,
    brand: 'Toyota',
    model: 'Hiace',
    manufactureYear: 2022,
    color: 'أبيض',
    capacity: 14,
    seatLayoutType: 'standard',
    imageUrl: '',
    notes: '',
    status: status,
    seatConfiguration: VehicleSeatConfigurator.resolve(
      type: VehicleType.hiace,
      capacity: 14,
    ),
    licenseExpiry: '',
    insuranceExpiry: '',
    inspectionExpiry: '',
  );
}

FleetVehicleDuty _duty({
  String vehicleId = 'v-1',
  required String status,
  DateTime? date,
}) {
  return FleetVehicleDuty(
    vehicleId: vehicleId,
    tripId: 't-1',
    tripCode: 'TR-1',
    status: status,
    tripDate: date ?? DateTime.now(),
    departureTime: '08:00:00',
    routeName: 'المرج - القاهرة الجديدة',
  );
}

FleetWorkspace _workspace(
  List<FleetVehicle> vehicles,
  List<FleetVehicleDuty> duties,
) {
  return FleetWorkspace(
    drivers: const [],
    vehicles: vehicles,
    assignments: const [],
    documents: const [],
    duties: duties,
  );
}

void main() {
  group('operational status', () {
    test('an active vehicle with no duty is available', () {
      final vehicle = _vehicle();
      expect(
        _workspace([vehicle], const []).operationalStatusOf(vehicle),
        FleetOperationalStatus.available,
      );
    });

    test('a vehicle committed to a future trip reads as assigned', () {
      final vehicle = _vehicle();
      final workspace = _workspace([vehicle], [
        _duty(
          status: 'open_for_booking',
          date: DateTime.now().add(const Duration(days: 3)),
        ),
      ]);
      expect(
        workspace.operationalStatusOf(vehicle),
        FleetOperationalStatus.assigned,
      );
    });

    test('a trip that has already run does not keep the vehicle assigned', () {
      final vehicle = _vehicle();
      final workspace = _workspace([vehicle], [
        _duty(
          status: 'scheduled',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]);
      expect(
        workspace.operationalStatusOf(vehicle),
        FleetOperationalStatus.available,
      );
    });

    test('a trip departing later today still counts as assigned', () {
      final vehicle = _vehicle();
      final workspace = _workspace([vehicle], [
        _duty(status: 'scheduled', date: DateTime.now()),
      ]);
      expect(
        workspace.operationalStatusOf(vehicle),
        FleetOperationalStatus.assigned,
      );
    });

    for (final status in const ['boarding', 'in_progress']) {
      test('a $status trip puts the vehicle on the road', () {
        final vehicle = _vehicle();
        final workspace = _workspace([vehicle], [_duty(status: status)]);
        expect(
          workspace.operationalStatusOf(vehicle),
          FleetOperationalStatus.onTrip,
        );
      });
    }

    test('lifecycle status is reported when no trip is under way', () {
      final cases = {
        FleetVehicleStatus.maintenance: FleetOperationalStatus.maintenance,
        FleetVehicleStatus.suspended: FleetOperationalStatus.unavailable,
        FleetVehicleStatus.archived: FleetOperationalStatus.retired,
      };

      cases.forEach((lifecycle, expected) {
        final vehicle = _vehicle(status: lifecycle);
        expect(
          _workspace([vehicle], const []).operationalStatusOf(vehicle),
          expected,
          reason: '${lifecycle.name} should read as ${expected.name}',
        );
      });
    });

    test(
      'a bus on the road reads as on-trip even when marked for maintenance',
      () {
        // The contradiction is deliberate and must stay visible: an observation
        // outranks an intent. The lifecycle chip is still rendered next to this
        // one, so the operator sees both rather than a laundered single answer.
        final vehicle = _vehicle(status: FleetVehicleStatus.maintenance);
        final workspace = _workspace([vehicle], [
          _duty(status: 'in_progress'),
        ]);
        expect(
          workspace.operationalStatusOf(vehicle),
          FleetOperationalStatus.onTrip,
        );
      },
    );

    test('another vehicle\'s duty never leaks onto this one', () {
      final mine = _vehicle(id: 'v-1');
      final theirs = _vehicle(id: 'v-2');
      final workspace = _workspace([mine, theirs], [
        _duty(vehicleId: 'v-2', status: 'in_progress'),
      ]);

      expect(
        workspace.operationalStatusOf(mine),
        FleetOperationalStatus.available,
      );
      expect(
        workspace.operationalStatusOf(theirs),
        FleetOperationalStatus.onTrip,
      );
    });
  });

  group('scheduling eligibility mirrors the database guard', () {
    test('maintenance, suspended and archived cannot take a new trip', () {
      expect(FleetOperationalStatus.maintenance.canTakeNewTrip, isFalse);
      expect(FleetOperationalStatus.unavailable.canTakeNewTrip, isFalse);
      expect(FleetOperationalStatus.retired.canTakeNewTrip, isFalse);
    });

    test('a busy but active vehicle may still be scheduled later', () {
      // Being on a trip does not disqualify a bus from a later departure — that
      // is precisely what the whole-day rule used to get wrong. Whether the
      // times overlap is the exclusion constraint's job, not this flag's.
      expect(FleetOperationalStatus.available.canTakeNewTrip, isTrue);
      expect(FleetOperationalStatus.assigned.canTakeNewTrip, isTrue);
      expect(FleetOperationalStatus.onTrip.canTakeNewTrip, isTrue);
    });
  });

  group('current duty', () {
    test('an in-flight trip is preferred over an upcoming one', () {
      final vehicle = _vehicle();
      final workspace = _workspace([vehicle], [
        _duty(
          status: 'scheduled',
          date: DateTime.now().add(const Duration(days: 1)),
        ),
        _duty(status: 'in_progress'),
      ]);
      expect(workspace.currentDutyOf(vehicle)?.status, 'in_progress');
    });

    test('the soonest upcoming trip is the one reported', () {
      final vehicle = _vehicle();
      final soon = DateTime.now().add(const Duration(days: 1));
      final later = DateTime.now().add(const Duration(days: 5));
      final workspace = _workspace([vehicle], [
        FleetVehicleDuty(
          vehicleId: 'v-1',
          tripId: 't-late',
          tripCode: 'TR-LATE',
          status: 'scheduled',
          tripDate: later,
          departureTime: '08:00:00',
        ),
        FleetVehicleDuty(
          vehicleId: 'v-1',
          tripId: 't-soon',
          tripCode: 'TR-SOON',
          status: 'scheduled',
          tripDate: soon,
          departureTime: '08:00:00',
        ),
      ]);
      expect(workspace.currentDutyOf(vehicle)?.tripCode, 'TR-SOON');
    });

    test('a vehicle with no duty reports none', () {
      final vehicle = _vehicle();
      expect(_workspace([vehicle], const []).currentDutyOf(vehicle), isNull);
    });
  });
}
