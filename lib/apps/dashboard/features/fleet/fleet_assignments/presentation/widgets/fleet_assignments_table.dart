import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
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

    return OpsDataTable(
      columns: const [
        OpsColumn('السائق', flex: 3),
        OpsColumn('المركبة', flex: 3),
        OpsColumn('تاريخ التعيين', flex: 2),
        OpsColumn('الحالة', flex: 2),
        OpsColumn('إجراءات', flex: 2),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            vehicle.isEmpty ? 'مركبة غير معروفة' : vehicle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            assignment.assignedAt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          StatusChip(label: assignment.status.label),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'تغيير المركبة',
                onPressed: () => onReassign(assignment),
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
              IconButton(
                tooltip: 'عرض السجل',
                onPressed: () => onViewHistory(assignment.history),
                icon: const Icon(Icons.history_rounded),
              ),
              PopupMenuButton<String>(
                tooltip: 'المزيد من الإجراءات',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'remove') {
                    cubit.removeAssignment(assignment.id);
                  } else if (value == 'delete') {
                    _confirmDeleteAssignment(context, assignment, cubit);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'remove',
                    enabled: assignment.status == FleetAssignmentStatus.active,
                    child: Row(
                      children: [
                        Icon(
                          Icons.link_off_rounded,
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          'فك التعيين',
                          style: TextStyle(
                            color:
                                assignment.status ==
                                    FleetAssignmentStatus.active
                                ? Theme.of(ctx).colorScheme.error
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          'حذف من قاعدة البيانات',
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }

  Future<void> _confirmDeleteAssignment(
    BuildContext context,
    FleetAssignment assignment,
    FleetAssignmentsCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التعيين نهائياً'),
        content: const Text(
          'سيتم حذف سجل التعيين من قاعدة البيانات. لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      cubit.deleteAssignment(assignment.id);
    }
  }
}
