import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/drivers/data/datasources/mock_drivers_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/drivers/data/models/driver_model.dart';
import 'package:bmt_app/apps/dashboard/features/drivers/data/repositories/drivers_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/drivers/domain/entities/driver.dart';
import 'package:bmt_app/apps/dashboard/features/drivers/domain/usecases/create_driver_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/drivers/domain/usecases/delete_driver_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/drivers/domain/usecases/get_drivers_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/drivers/domain/usecases/update_driver_status_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/drivers/domain/usecases/update_driver_usecase.dart';

void main() {
  group('Drivers clean architecture chain', () {
    test('loads realistic dummy drivers', () async {
      final repository = DriversRepositoryImpl(MockDriversDatasource());
      final getDrivers = GetDriversUseCase(repository);

      final drivers = await getDrivers();

      expect(drivers, isNotEmpty);
      expect(drivers.first.name, 'محمد أحمد');
      expect(
        drivers.first.documents.map((doc) => doc.title),
        contains('رخصة القيادة'),
      );
      expect(drivers.first.reviews, isNotEmpty);
    });

    test(
      'creates, updates status, edits, and deletes driver locally',
      () async {
        final repository = DriversRepositoryImpl(MockDriversDatasource());
        final getDrivers = GetDriversUseCase(repository);
        final createDriver = CreateDriverUseCase(repository);
        final updateDriver = UpdateDriverUseCase(repository);
        final updateStatus = UpdateDriverStatusUseCase(repository);
        final deleteDriver = DeleteDriverUseCase(repository);

        final created = await createDriver(_newDriver);
        expect(created.id, isNotEmpty);

        final activated = await updateStatus(created.id, DriverStatus.active);
        expect(activated.status, DriverStatus.active);

        final edited = await updateDriver(
          activated.copyWith(name: 'أحمد سامي'),
        );
        expect(edited.name, 'أحمد سامي');

        await deleteDriver(created.id);
        final drivers = await getDrivers();
        expect(drivers.any((driver) => driver.id == created.id), isFalse);
      },
    );

    test('maps datasource failures to Arabic repository error', () async {
      final repository = DriversRepositoryImpl(_FailingDriversDatasource());
      final getDrivers = GetDriversUseCase(repository);

      expect(
        getDrivers.call,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل السائقين'),
          ),
        ),
      );
    });
  });
}

const _newDriver = Driver(
  id: '',
  name: 'سائق اختبار',
  phone: '٠١٠٠٠٠٠٠٠٠٠',
  nationalId: '٢٩٩٠١٠١٠١٠١٠١٠',
  email: 'test@bmt.local',
  address: 'القاهرة',
  avatarInitials: 'س ا',
  currentVehicle: 'غير مسند',
  currentRoute: 'غير مسند',
  totalTrips: 0,
  todayTrips: 0,
  monthlyTrips: 0,
  totalPassengers: 0,
  rating: 0,
  status: DriverStatus.pendingDocuments,
  assignedAt: 'اليوم',
  licenseNumber: 'ر-اختبار',
  licenseExpiry: '٢٠٢٧',
  documents: [],
  reviews: [],
  complaints: [],
  notes: [],
);

class _FailingDriversDatasource implements DriversDatasource {
  @override
  Future<DriverModel> createDriver(Driver driver) {
    throw StateError('failure');
  }

  @override
  Future<void> deleteDriver(String driverId) {
    throw StateError('failure');
  }

  @override
  Future<List<DriverModel>> fetchDrivers() {
    throw StateError('failure');
  }

  @override
  Future<DriverModel> updateDriver(Driver driver) {
    throw StateError('failure');
  }

  @override
  Future<DriverModel> updateDriverStatus(String driverId, DriverStatus status) {
    throw StateError('failure');
  }
}
