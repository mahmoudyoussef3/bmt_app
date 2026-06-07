import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/vehicles/data/datasources/mock_vehicles_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/vehicles/data/models/vehicle_model.dart';
import 'package:bmt_app/apps/dashboard/features/vehicles/data/repositories/vehicles_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/vehicles/domain/entities/vehicle.dart';
import 'package:bmt_app/apps/dashboard/features/vehicles/domain/usecases/create_vehicle_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/vehicles/domain/usecases/renew_vehicle_document_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/vehicles/domain/usecases/update_vehicle_status_usecase.dart';

void main() {
  group('Vehicles clean architecture chain', () {
    test('loads visual fleet dummy data', () async {
      final repository = VehiclesRepositoryImpl(MockVehiclesDatasource());
      final getVehicles = GetVehiclesUseCase(repository);

      final vehicles = await getVehicles();

      expect(vehicles, isNotEmpty);
      expect(vehicles.first.plateNumber, 'أ ب ج ٤٥٦');
      expect(
        vehicles.first.documents.map((doc) => doc.title),
        contains('رخصة المركبة'),
      );
      expect(vehicles.first.maintenance, isNotEmpty);
    });

    test(
      'creates vehicle, updates status, and renews document locally',
      () async {
        final repository = VehiclesRepositoryImpl(MockVehiclesDatasource());
        final createVehicle = CreateVehicleUseCase(repository);
        final updateStatus = UpdateVehicleStatusUseCase(repository);
        final renewDocument = RenewVehicleDocumentUseCase(repository);

        final created = await createVehicle(_newVehicle);
        expect(created.id, isNotEmpty);
        expect(created.status, VehicleStatus.pendingAssignment);

        final active = await updateStatus(created.id, VehicleStatus.active);
        expect(active.status, VehicleStatus.active);

        final renewed = await renewDocument(active.id, 'رخصة المركبة');
        final license = renewed.documents.firstWhere(
          (document) => document.title == 'رخصة المركبة',
        );
        expect(license.expired, isFalse);
        expect(license.expirationDate, '٣١ ديسمبر ٢٠٢٧');
      },
    );

    test('maps datasource failures to Arabic repository error', () {
      final repository = VehiclesRepositoryImpl(_FailingVehiclesDatasource());
      final getVehicles = GetVehiclesUseCase(repository);

      expect(
        getVehicles.call,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل المركبات'),
          ),
        ),
      );
    });
  });
}

const _newVehicle = Vehicle(
  id: '',
  plateNumber: 'ت ج ر ١٠٠',
  type: 'ميني باص',
  model: 'اختبار ٢٠٢٦',
  capacity: 12,
  status: VehicleStatus.pendingAssignment,
  currentDriver: 'بانتظار التعيين',
  currentRoute: 'بانتظار التعيين',
  licenseExpiry: 'غير محدد',
  insuranceExpiry: 'غير محدد',
  inspectionExpiry: 'غير محدد',
  imageLabel: 'مركبة اختبار',
  documents: [
    VehicleDocument(
      title: 'رخصة المركبة',
      number: 'غير محدد',
      expirationDate: 'منتهية',
      previewLabel: 'صورة الرخصة',
      expired: true,
    ),
  ],
  maintenance: [],
  trips: [],
  previousDrivers: [],
  notes: [],
);

class _FailingVehiclesDatasource implements VehiclesDatasource {
  @override
  Future<VehicleModel> createVehicle(Vehicle vehicle) {
    throw StateError('failure');
  }

  @override
  Future<List<VehicleModel>> fetchVehicles() {
    throw StateError('failure');
  }

  @override
  Future<VehicleModel> renewDocument(String vehicleId, String documentTitle) {
    throw StateError('failure');
  }

  @override
  Future<VehicleModel> updateVehicle(Vehicle vehicle) {
    throw StateError('failure');
  }

  @override
  Future<VehicleModel> updateVehicleStatus(
    String vehicleId,
    VehicleStatus status,
  ) {
    throw StateError('failure');
  }
}
