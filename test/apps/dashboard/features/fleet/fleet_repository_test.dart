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
      expect(workspace.summary.documentsNeedFollowUpCount, greaterThan(0));
    });

    test('creates and updates drivers locally', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final createDriver = CreateFleetDriverUseCase(repository);
      final updateDriver = UpdateFleetDriverUseCase(repository);
      final updateStatus = UpdateFleetDriverStatusUseCase(repository);

      final created = await createDriver(_driver);
      expect(created.id, isNotEmpty);
      expect(created.name, 'سائق اختبار');

      final edited = await updateDriver(created.copyWith(phone: '01099999999'));
      expect(edited.phone, '01099999999');

      final suspended = await updateStatus(
        edited.id,
        FleetDriverStatus.suspended,
      );
      expect(suspended.status, FleetDriverStatus.suspended);
    });

    test('creates vehicles and prevents duplicate assignments', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final getWorkspace = GetFleetWorkspaceUseCase(repository);
      final createVehicle = CreateFleetVehicleUseCase(repository);
      final assign = AssignFleetVehicleUseCase(repository);

      final vehicle = await createVehicle(_vehicle);
      expect(vehicle.id, isNotEmpty);

      final workspace = await getWorkspace();
      final freeDriver = workspace.drivers.firstWhere(
        (driver) => driver.currentVehicleId.isEmpty,
      );
      final assignment = await assign(freeDriver.id, vehicle.id);
      expect(assignment.status, FleetAssignmentStatus.active);

      expect(
        () => assign(freeDriver.id, vehicle.id),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر إنشاء التعيين'),
          ),
        ),
      );
    });

    test('reassigns vehicle and keeps assignment history', () async {
      final repository = FleetRepositoryImpl(MockFleetDatasource());
      final getWorkspace = GetFleetWorkspaceUseCase(repository);
      final createVehicle = CreateFleetVehicleUseCase(repository);
      final reassign = ReassignFleetVehicleUseCase(repository);
      final remove = RemoveUnifiedFleetAssignmentUseCase(repository);

      final workspace = await getWorkspace();
      final assignment = workspace.assignments.first;
      final newVehicle = await createVehicle(
        _vehicle.copyWith(vehicleNumber: 'مركبة إعادة', plateNumber: '٩٩٩ ق ل'),
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
  imageLabel: '',
  name: 'سائق اختبار',
  phone: '01012345678',
  nationalId: '29901011234567',
  licenseNumber: 'د-اختبار',
  licenseExpiry: '١ ديسمبر ٢٠٢٦',
  status: FleetDriverStatus.active,
  address: 'القاهرة',
  emergencyContact: '01212345678',
  documents: [
    FleetDocument(
      id: 'doc-test',
      type: FleetDocumentType.driverLicense,
      ownerId: '',
      ownerName: 'سائق اختبار',
      referenceNumber: 'د-اختبار',
      expiryDate: '١ ديسمبر ٢٠٢٦',
      status: FleetDocumentStatus.valid,
    ),
  ],
);

const _vehicle = FleetVehicle(
  id: '',
  imageLabel: '',
  vehicleNumber: 'مركبة اختبار',
  plateNumber: '١٢٣ ق ل',
  model: 'تويوتا هايس',
  modelYear: 2022,
  seatsCount: 14,
  status: FleetVehicleStatus.active,
  licenseExpiry: '١ ديسمبر ٢٠٢٦',
  insuranceExpiry: '١ يناير ٢٠٢٧',
  inspectionExpiry: '١ فبراير ٢٠٢٧',
);
