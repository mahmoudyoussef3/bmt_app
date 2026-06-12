import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/cubit/fleet_assignments_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetAssignmentsCardList extends StatelessWidget {
  final List<FleetAssignment> assignments;
  final FleetWorkspace workspace;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<FleetAssignment> onReassign;
  final void Function(List<FleetHistoryItem>) onViewHistory;

  const FleetAssignmentsCardList({
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
    final paged = start >= assignments.length ? <FleetAssignment>[] : assignments.sublist(start, end);

    if (paged.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Text('لا توجد بيانات مطابقة'),
        ),
      );
    }

    final pages = (assignments.length / pageSize).ceil().clamp(1, 9999);

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paged.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
          itemBuilder: (context, index) {
            final assignment = paged[index];
            final driverName = _driverName(assignment.driverId);
            final vehicleName = _vehicleName(assignment.vehicleId);

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'تعيين #${assignment.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      StatusChip(label: assignment.status.label),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.small),
                  FleetMetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'السائق',
                    value: driverName.isEmpty ? 'سائق غير معروف' : driverName,
                  ),
                  FleetMetaRow(
                    icon: Icons.directions_bus_outlined,
                    label: 'المركبة',
                    value: vehicleName.isEmpty ? 'مركبة غير معروفة' : vehicleName,
                  ),
                  FleetMetaRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'تاريخ التعيين',
                    value: assignment.assignedAt,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                      IconButton(
                        icon: const Icon(Icons.history_rounded),
                        tooltip: 'عرض السجل',
                        onPressed: () => onViewHistory(assignment.history),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.small),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: page == 0 ? null : () => onPageChanged(page - 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              Text('صفحة ${page + 1} من $pages'),
              IconButton(
                onPressed: page >= pages - 1 ? null : () => onPageChanged(page + 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
