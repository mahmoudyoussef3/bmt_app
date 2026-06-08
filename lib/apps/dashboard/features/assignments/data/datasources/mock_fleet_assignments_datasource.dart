import '../../domain/entities/fleet_assignment.dart';
import '../models/fleet_assignment_model.dart';

abstract class FleetAssignmentsDatasource {
  Future<FleetAssignmentsData> fetchAssignmentsData();

  Future<FleetAssignmentModel> assignVehicleToDriver({
    required String driverId,
    required String vehicleId,
    required String route,
    required String reason,
  });

  Future<FleetAssignmentModel> changeAssignment({
    required String assignmentId,
    required String vehicleId,
    required String route,
    required String reason,
  });

  Future<FleetAssignmentModel> removeAssignment({
    required String assignmentId,
    required String reason,
  });
}

class MockFleetAssignmentsDatasource implements FleetAssignmentsDatasource {
  final List<FleetAssignmentModel> _assignments =
      List<FleetAssignmentModel>.from(_seedAssignments);

  @override
  Future<FleetAssignmentsData> fetchAssignmentsData() async {
    return FleetAssignmentsData(
      assignments: List<FleetAssignment>.unmodifiable(_assignments),
      drivers: _drivers,
      vehicles: _vehicles,
      routes: _routes,
    );
  }

  @override
  Future<FleetAssignmentModel> assignVehicleToDriver({
    required String driverId,
    required String vehicleId,
    required String route,
    required String reason,
  }) async {
    final driver = _driverById(driverId);
    final vehicle = _vehicleById(vehicleId);
    _closeConflictingAssignments(driverId, vehicleId, 'تم إنشاء تعيين أحدث');
    final assignment = FleetAssignmentModel(
      id: 'asg-${_assignments.length + 20}',
      driverId: driver.id,
      driverName: driver.name,
      vehicleId: vehicle.id,
      vehiclePlate: vehicle.plateNumber,
      route: route,
      startedAt: 'اليوم',
      status: FleetAssignmentStatus.active,
      reason: reason,
      timeline: [
        AssignmentTimelineEvent(
          title: 'تم التعيين',
          date: 'اليوم',
          description: '$reason على مسار $route',
        ),
      ],
    );
    _assignments.insert(0, assignment);
    return assignment;
  }

  @override
  Future<FleetAssignmentModel> changeAssignment({
    required String assignmentId,
    required String vehicleId,
    required String route,
    required String reason,
  }) async {
    final index = _assignments.indexWhere((item) => item.id == assignmentId);
    if (index == -1) throw ArgumentError('Assignment not found');
    final current = _assignments[index];
    final vehicle = _vehicleById(vehicleId);
    _closeConflictingAssignments(current.driverId, vehicleId, reason);
    final updated = FleetAssignmentModel.fromEntity(
      current.copyWith(
        vehicleId: vehicle.id,
        vehiclePlate: vehicle.plateNumber,
        route: route,
        status: FleetAssignmentStatus.active,
        reason: reason,
        clearEndedAt: true,
        timeline: [
          AssignmentTimelineEvent(
            title: 'تم تغيير التعيين',
            date: 'اليوم',
            description: 'نقل إلى ${vehicle.plateNumber} على مسار $route',
          ),
          ...current.timeline,
        ],
      ),
    );
    _assignments[index] = updated;
    return updated;
  }

  @override
  Future<FleetAssignmentModel> removeAssignment({
    required String assignmentId,
    required String reason,
  }) async {
    final index = _assignments.indexWhere((item) => item.id == assignmentId);
    if (index == -1) throw ArgumentError('Assignment not found');
    final current = _assignments[index];
    final updated = FleetAssignmentModel.fromEntity(
      current.copyWith(
        endedAt: 'اليوم',
        status: FleetAssignmentStatus.ended,
        reason: reason,
        timeline: [
          AssignmentTimelineEvent(
            title: 'تمت إزالة التعيين',
            date: 'اليوم',
            description: reason,
          ),
          ...current.timeline,
        ],
      ),
    );
    _assignments[index] = updated;
    return updated;
  }

  void _closeConflictingAssignments(
    String driverId,
    String vehicleId,
    String reason,
  ) {
    for (var index = 0; index < _assignments.length; index += 1) {
      final assignment = _assignments[index];
      final conflict =
          assignment.status == FleetAssignmentStatus.active &&
          (assignment.driverId == driverId ||
              assignment.vehicleId == vehicleId);
      if (!conflict) continue;
      _assignments[index] = FleetAssignmentModel.fromEntity(
        assignment.copyWith(
          endedAt: 'اليوم',
          status: FleetAssignmentStatus.changed,
          timeline: [
            AssignmentTimelineEvent(
              title: 'إغلاق تعيين سابق',
              date: 'اليوم',
              description: reason,
            ),
            ...assignment.timeline,
          ],
        ),
      );
    }
  }

  AssignmentDriverOption _driverById(String id) {
    return _drivers.firstWhere((driver) => driver.id == id);
  }

  AssignmentVehicleOption _vehicleById(String id) {
    return _vehicles.firstWhere((vehicle) => vehicle.id == id);
  }
}

const _drivers = [
  AssignmentDriverOption(
    id: 'drv-1',
    name: 'محمد أحمد',
    status: 'نشط',
    rating: 4.8,
  ),
  AssignmentDriverOption(
    id: 'drv-2',
    name: 'كريم حسن',
    status: 'نشط',
    rating: 4.6,
  ),
  AssignmentDriverOption(
    id: 'drv-3',
    name: 'هاني صلاح',
    status: 'بانتظار مستندات',
    rating: 4.3,
  ),
  AssignmentDriverOption(
    id: 'drv-4',
    name: 'مصطفى علي',
    status: 'في إجازة',
    rating: 4.1,
  ),
];

const _vehicles = [
  AssignmentVehicleOption(
    id: 'veh-1',
    plateNumber: 'أ ب ج ٤٥٦',
    model: 'تويوتا كوستر ٢٠٢٣',
    capacity: 12,
    status: 'نشطة',
  ),
  AssignmentVehicleOption(
    id: 'veh-2',
    plateNumber: 'س د هـ ٧٨٩',
    model: 'هيونداي H1 ٢٠٢٢',
    capacity: 8,
    status: 'نشطة',
  ),
  AssignmentVehicleOption(
    id: 'veh-4',
    plateNumber: 'ر ز ط ١٢٣',
    model: 'كيا كارنيفال ٢٠٢٤',
    capacity: 7,
    status: 'جاهزة للتعيين',
  ),
];

const _routes = [
  'بنها - القرية الذكية',
  'بنها - مدينة نصر',
  'بنها - المهندسين',
  'بنها - المعادي',
];

const _seedAssignments = [
  FleetAssignmentModel(
    id: 'asg-1',
    driverId: 'drv-1',
    driverName: 'محمد أحمد',
    vehicleId: 'veh-1',
    vehiclePlate: 'أ ب ج ٤٥٦',
    route: 'بنها - القرية الذكية',
    startedAt: '١ مايو ٢٠٢٦',
    status: FleetAssignmentStatus.active,
    reason: 'تثبيت سائق عالي التقييم على مسار صباحي مزدحم',
    timeline: [
      AssignmentTimelineEvent(
        title: 'تعيين نشط',
        date: '١ مايو ٢٠٢٦',
        description: 'محمد أحمد يقود أ ب ج ٤٥٦ على مسار القرية الذكية',
      ),
      AssignmentTimelineEvent(
        title: 'اعتماد مشرف التشغيل',
        date: '٣٠ أبريل ٢٠٢٦',
        description: 'تمت مراجعة الرخصة والتأمين والفحص الفني',
      ),
    ],
  ),
  FleetAssignmentModel(
    id: 'asg-2',
    driverId: 'drv-2',
    driverName: 'كريم حسن',
    vehicleId: 'veh-2',
    vehiclePlate: 'س د هـ ٧٨٩',
    route: 'بنها - مدينة نصر',
    startedAt: '١٨ أبريل ٢٠٢٦',
    status: FleetAssignmentStatus.active,
    reason: 'تغطية مسار مدينة نصر في أوقات الذروة',
    timeline: [
      AssignmentTimelineEvent(
        title: 'تعيين نشط',
        date: '١٨ أبريل ٢٠٢٦',
        description: 'كريم حسن يقود س د هـ ٧٨٩',
      ),
    ],
  ),
  FleetAssignmentModel(
    id: 'asg-3',
    driverId: 'drv-4',
    driverName: 'مصطفى علي',
    vehicleId: 'veh-4',
    vehiclePlate: 'ر ز ط ١٢٣',
    route: 'بنها - المهندسين',
    startedAt: '١ مارس ٢٠٢٦',
    endedAt: '٢٨ مارس ٢٠٢٦',
    status: FleetAssignmentStatus.ended,
    reason: 'انتهاء تغطية مؤقتة أثناء صيانة مركبة أخرى',
    timeline: [
      AssignmentTimelineEvent(
        title: 'تمت إزالة التعيين',
        date: '٢٨ مارس ٢٠٢٦',
        description: 'السائق دخل إجازة تشغيلية',
      ),
      AssignmentTimelineEvent(
        title: 'تعيين مؤقت',
        date: '١ مارس ٢٠٢٦',
        description: 'تغطية مسار المهندسين لمدة شهر',
      ),
    ],
  ),
];
