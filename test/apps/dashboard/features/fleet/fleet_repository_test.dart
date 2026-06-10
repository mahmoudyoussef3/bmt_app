import 'package:flutter_test/flutter_test.dart';

import 'test_fleet_datasource.dart';
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

    test('creates driver with vehicle assignment and auto-links them', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final getWorkspace = GetFleetWorkspaceUseCase(repository);
      final createDriver = CreateFleetDriverUseCase(repository);
      final createVehicle = CreateFleetVehicleUseCase(repository);

      // Create a new vehicle (so it is free)
      final freeVehicle = await createVehicle(
        _vehicle.copyWith(vehicleCode: 'BUS-NEW-1', plateNumber: '١١١ ق ل'),
      );

      // Create driver with this vehicle's ID
      final driverToCreate = _driver.copyWith(
        employeeCode: 'EMP-UNIQUE-1',
        nationalId: '29901011234577',
        licenseNumber: 'د-رخصة-1',
        currentVehicleId: freeVehicle.id,
      );

      final created = await createDriver(driverToCreate);
      expect(created.currentVehicleId, freeVehicle.id);

      // Verify assignment was created and vehicle's driver was updated
      final updatedWorkspace = await getWorkspace();
      final updatedVehicle = updatedWorkspace.vehicles.firstWhere((v) => v.id == freeVehicle.id);
      expect(updatedVehicle.currentDriverId, created.id);

      final hasActiveAssignment = updatedWorkspace.assignments.any(
        (a) => a.driverId == created.id && a.vehicleId == freeVehicle.id && a.status == FleetAssignmentStatus.active,
      );
      expect(hasActiveAssignment, isTrue);
    });

    test('updates driver to change vehicle and updates assignment', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final getWorkspace = GetFleetWorkspaceUseCase(repository);
      final createDriver = CreateFleetDriverUseCase(repository);
      final updateDriver = UpdateFleetDriverUseCase(repository);
      final createVehicle = CreateFleetVehicleUseCase(repository);

      // Create two new vehicles
      final vehicle1 = await createVehicle(
        _vehicle.copyWith(vehicleCode: 'BUS-NEW-2', plateNumber: '٢٢٢ ق ل'),
      );
      final vehicle2 = await createVehicle(
        _vehicle.copyWith(vehicleCode: 'BUS-NEW-3', plateNumber: '٣٣٣ ق ل'),
      );

      // Create driver with vehicle1
      final created = await createDriver(
        _driver.copyWith(
          employeeCode: 'EMP-UNIQUE-2',
          nationalId: '29901011234578',
          licenseNumber: 'د-رخصة-2',
          currentVehicleId: vehicle1.id,
        ),
      );

      // Update driver to vehicle2
      final updated = await updateDriver(created.copyWith(currentVehicleId: vehicle2.id));
      expect(updated.currentVehicleId, vehicle2.id);

      // Verify that assignment for vehicle1 is ended, and active assignment for vehicle2 is created
      final updatedWorkspace = await getWorkspace();
      
      // vehicle1 should now be free
      final updatedVehicle1 = updatedWorkspace.vehicles.firstWhere((v) => v.id == vehicle1.id);
      expect(updatedVehicle1.currentDriverId, isEmpty);

      // vehicle2 should be linked to driver
      final updatedVehicle2 = updatedWorkspace.vehicles.firstWhere((v) => v.id == vehicle2.id);
      expect(updatedVehicle2.currentDriverId, created.id);

      final hasVehicle2Assignment = updatedWorkspace.assignments.any(
        (a) => a.driverId == created.id && a.vehicleId == vehicle2.id && a.status == FleetAssignmentStatus.active,
      );
      expect(hasVehicle2Assignment, isTrue);
    });

    test('creates vehicle with driver assignment and auto-links them', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final getWorkspace = GetFleetWorkspaceUseCase(repository);
      final createVehicle = CreateFleetVehicleUseCase(repository);
      final createDriver = CreateFleetDriverUseCase(repository);

      // Create a new driver (so they are free)
      final freeDriver = await createDriver(
        _driver.copyWith(
          employeeCode: 'EMP-UNIQUE-3',
          nationalId: '29901011234579',
          licenseNumber: 'د-رخصة-3',
          currentVehicleId: '',
        ),
      );

      // Create vehicle with driver ID
      final vehicleToCreate = _vehicle.copyWith(
        vehicleCode: 'BUS-UNIQUE-4',
        plateNumber: '٤٤٤ ق ل',
        currentDriverId: freeDriver.id,
      );

      final created = await createVehicle(vehicleToCreate);
      expect(created.currentDriverId, freeDriver.id);

      // Verify assignment was created and driver's vehicle was updated
      final updatedWorkspace = await getWorkspace();
      final updatedDriver = updatedWorkspace.drivers.firstWhere((d) => d.id == freeDriver.id);
      expect(updatedDriver.currentVehicleId, created.id);

      final hasActiveAssignment = updatedWorkspace.assignments.any(
        (a) => a.driverId == freeDriver.id && a.vehicleId == created.id && a.status == FleetAssignmentStatus.active,
      );
      expect(hasActiveAssignment, isTrue);
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
