import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_table_shell.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/cubit/fleet_assignments_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetAssignmentsTable extends StatelessWidget {
  final List<FleetAssignment> assignments;
  final FleetWorkspace workspace;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<FleetAssignment> onReassign;
  final void Function(List<FleetHistoryItem>) onViewHistory;

  const FleetAssignmentsTable({
    super.key,
    required this.assignments,
    required this.workspace,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.onReassign,
    required this.onViewHistory,
  });

  String _driverName(String driverId) {
    if (driverId.isEmpty) return '';
    final match = workspace.drivers.where((d) => d.id == driverId);
    if (match.isEmpty) return '';
    return match.first.name;
  }

  String _vehicleName(String vehicleId) {
    if (vehicleId.isEmpty) return '';
    final match = workspace.vehicles.where((v) => v.id == vehicleId);
    if (match.isEmpty) return '';
    return match.first.vehicleNumber;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetAssignmentsCubit>();
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, assignments.length);
    final paged = start >= assignments.length
        ? <FleetAssignment>[]
        : assignments.sublist(start, end);

    return FleetTableShell(
      headers: const [
        'السائق',
        'المركبة',
        'تاريخ التعيين',
        'الحالة',
        'إجراءات',
      ],
      total: assignments.length,
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      rows: paged.map((assignment) {
        final driver = _driverName(assignment.driverId);
        final vehicle = _vehicleName(assignment.vehicleId);
        return [
          Text(
            driver.isEmpty ? 'سائق غير معروف' : driver,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(vehicle.isEmpty ? 'مركبة غير معروفة' : vehicle),
          Text(assignment.assignedAt),
          StatusChip(label: assignment.status.label),
          Wrap(
            spacing: AppSpacing.xSmall,
            children: [
              TextButton(
                onPressed: () => onReassign(assignment),
                child: const Text('تغيير المركبة'),
              ),
              TextButton(
                onPressed: assignment.status == FleetAssignmentStatus.active
                    ? () => cubit.removeAssignment(assignment.id)
                    : null,
                child: const Text('فك التعيين'),
              ),
              TextButton(
                onPressed: () => onViewHistory(assignment.history),
                child: const Text('عرض السجل'),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }
}
