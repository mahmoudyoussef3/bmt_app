import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/assignments/data/datasources/mock_fleet_assignments_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/assignments/data/models/fleet_assignment_model.dart';
import 'package:bmt_app/apps/dashboard/features/assignments/data/repositories/fleet_assignments_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/assignments/domain/entities/fleet_assignment.dart';
import 'package:bmt_app/apps/dashboard/features/assignments/domain/usecases/assign_vehicle_to_driver_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/assignments/domain/usecases/change_fleet_assignment_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/assignments/domain/usecases/get_fleet_assignments_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/assignments/domain/usecases/remove_fleet_assignment_usecase.dart';

void main() {
  group('Fleet assignments clean architecture chain', () {
    test('loads dummy assignments with options and timeline', () async {
      final repository = FleetAssignmentsRepositoryImpl(
        MockFleetAssignmentsDatasource(),
      );
      final getAssignments = GetFleetAssignmentsUseCase(repository);

      final data = await getAssignments();

      expect(data.assignments, isNotEmpty);
      expect(data.drivers, isNotEmpty);
      expect(data.vehicles, isNotEmpty);
      expect(data.assignments.first.timeline, isNotEmpty);
    });

    test('assigns, changes, and removes vehicle assignment locally', () async {
      final repository = FleetAssignmentsRepositoryImpl(
        MockFleetAssignmentsDatasource(),
      );
      final getAssignments = GetFleetAssignmentsUseCase(repository);
      final assign = AssignVehicleToDriverUseCase(repository);
      final change = ChangeFleetAssignmentUseCase(repository);
      final remove = RemoveFleetAssignmentUseCase(repository);

      final created = await assign(
        driverId: 'drv-3',
        vehicleId: 'veh-4',
        route: 'بنها - المهندسين',
        reason: 'اختبار تعيين',
      );
      expect(created.status, FleetAssignmentStatus.active);

      final changed = await change(
        assignmentId: created.id,
        vehicleId: 'veh-2',
        route: 'بنها - مدينة نصر',
        reason: 'اختبار تغيير',
      );
      expect(changed.vehicleId, 'veh-2');
      expect(changed.timeline.first.title, 'تم تغيير التعيين');

      final removed = await remove(
        assignmentId: changed.id,
        reason: 'اختبار إزالة',
      );
      expect(removed.status, FleetAssignmentStatus.ended);

      final data = await getAssignments();
      expect(
        data.assignments.firstWhere((item) => item.id == removed.id).endedAt,
        'اليوم',
      );
    });

    test('maps datasource failures to Arabic repository error', () async {
      final repository = FleetAssignmentsRepositoryImpl(
        _FailingFleetAssignmentsDatasource(),
      );
      final getAssignments = GetFleetAssignmentsUseCase(repository);

      expect(
        getAssignments.call,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل تعيينات الأسطول'),
          ),
        ),
      );
    });
  });
}

class _FailingFleetAssignmentsDatasource implements FleetAssignmentsDatasource {
  @override
  Future<FleetAssignmentModel> assignVehicleToDriver({
    required String driverId,
    required String vehicleId,
    required String route,
    required String reason,
  }) {
    throw StateError('failure');
  }

  @override
  Future<FleetAssignmentModel> changeAssignment({
    required String assignmentId,
    required String vehicleId,
    required String route,
    required String reason,
  }) {
    throw StateError('failure');
  }

  @override
  Future<FleetAssignmentsData> fetchAssignmentsData() {
    throw StateError('failure');
  }

  @override
  Future<FleetAssignmentModel> removeAssignment({
    required String assignmentId,
    required String reason,
  }) {
    throw StateError('failure');
  }
}
