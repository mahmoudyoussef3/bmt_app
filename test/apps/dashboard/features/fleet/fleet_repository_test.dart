import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/data/datasources/mock_fleet_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/domain/usecases/fleet_usecases.dart';

void main() {
  group('Fleet clean architecture chain', () {
    test('loads realistic fleet workspace data', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final getWorkspace = GetFleetWorkspaceUseCase(repository);

      final workspace = await getWorkspace();

      expect(workspace.drivers, hasLength(25));
      expect(workspace.vehicles, hasLength(15));
      expect(
        workspace.assignments
            .where(
              (assignment) => assignment.status == FleetAssignmentStatus.active,
            )
            .length,
        15,
      );
      expect(workspace.documents, isNotEmpty);
    });

    test('creates and updates drivers with production fields', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final createDriver = CreateFleetDriverUseCase(repository);
      final updateDriver = UpdateFleetDriverUseCase(repository);
      final updateStatus = UpdateFleetDriverStatusUseCase(repository);

      final created = await createDriver(_driver);
      expect(created.id, isNotEmpty);
      expect(created.employeeCode, 'EMP-999');
      expect(created.fullName, 'سائق اختبار');

      final edited = await updateDriver(created.copyWith(phone: '01099999999'));
      expect(edited.phone, '01099999999');

      final suspended = await updateStatus(
        edited.id,
        FleetDriverStatus.suspended,
      );
      expect(suspended.status, FleetDriverStatus.suspended);
    });

    test('creates vehicles and validates active/inactive status constraints', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final getWorkspace = GetFleetWorkspaceUseCase(repository);
      final createVehicle = CreateFleetVehicleUseCase(repository);
      final assign = AssignFleetVehicleUseCase(repository);

      final vehicle = await createVehicle(_vehicle);
      expect(vehicle.id, isNotEmpty);
      expect(vehicle.seatConfiguration.seats, isNotEmpty);

      final workspace = await getWorkspace();
      final freeDriver = workspace.drivers.firstWhere(
        (driver) => driver.currentVehicleId.isEmpty && driver.status == FleetDriverStatus.active,
      );
      
      final assignment = await assign(freeDriver.id, vehicle.id);
      expect(assignment.status, FleetAssignmentStatus.active);

      expect(
        () => assign(freeDriver.id, vehicle.id),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('مرتبط بالفعل بتعيين نشط'),
          ),
        ),
      );
    });

    test('reassigns vehicle and updates audit timeline log', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final getWorkspace = GetFleetWorkspaceUseCase(repository);
      final createVehicle = CreateFleetVehicleUseCase(repository);
      final reassign = ReassignFleetVehicleUseCase(repository);
      final remove = RemoveUnifiedFleetAssignmentUseCase(repository);

      final workspace = await getWorkspace();
      final assignment = workspace.assignments.first;
      final newVehicle = await createVehicle(
        _vehicle.copyWith(vehicleCode: 'BUS-999', plateNumber: '٩٩٩ ق ل'),
      );

      final changed = await reassign(assignment.id, newVehicle.id);
      expect(changed.vehicleId, newVehicle.id);
      expect(changed.history.length, greaterThan(assignment.history.length));

      final ended = await remove(changed.id);
      expect(ended.status, FleetAssignmentStatus.ended);
    });
  });
}

const _driver = FleetDriver(
  id: '',
  employeeCode: 'EMP-999',
  fullName: 'سائق اختبار',
  phone: '01012345678',
  emergencyPhone: '01212345678',
  address: 'القاهرة',
  nationalId: '29901011234567',
  profileImageUrl: '',
  licenseNumber: 'د-اختبار',
  licenseExpiryDate: '2026-12-01',
  hireDate: '2026-06-01',
  notes: 'ملاحظات اختبار',
  status: FleetDriverStatus.active,
  documents: [
    FleetDocument(
      id: 'doc-test',
      type: FleetDocumentType.driverLicense,
      ownerId: '',
      ownerName: 'سائق اختبار',
      referenceNumber: 'د-اختبار',
      expiryDate: '2026-12-01',
      status: FleetDocumentStatus.valid,
    ),
  ],
);

final _vehicle = FleetVehicle(
  id: '',
  vehicleCode: 'BUS-888',
  plateNumber: '١٢٣ ق ل',
  vehicleType: 'Hiace',
  brand: 'Toyota',
  model: 'هايس',
  manufactureYear: 2022,
  color: 'أبيض',
  capacity: 14,
  seatLayoutType: 'standard',
  imageUrl: '',
  notes: 'ملاحظات اختبار مركبة',
  status: FleetVehicleStatus.active,
  seatConfiguration: SeatConfiguration.generateDefault(14),
  licenseExpiry: '2026-12-01',
  insuranceExpiry: '2027-01-01',
  inspectionExpiry: '2027-02-01',
);
