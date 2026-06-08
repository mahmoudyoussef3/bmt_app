import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/fleet_assignment.dart';
import '../cubit/fleet_assignments_cubit.dart';
import '../cubit/fleet_assignments_state.dart';

class FleetAssignmentsScreen extends StatelessWidget {
  const FleetAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FleetAssignmentsCubit, FleetAssignmentsState>(
      builder: (context, state) {
        return switch (state) {
          FleetAssignmentsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          FleetAssignmentsError(:final message) => _AssignmentsError(
            message: message,
          ),
          FleetAssignmentsLoaded() => _AssignmentsLoadedView(state: state),
        };
      },
    );
  }
}

class _AssignmentsLoadedView extends StatelessWidget {
  final FleetAssignmentsLoaded state;

  const _AssignmentsLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedAssignment;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _AssignmentsHeader(state: state),
        const SizedBox(height: AppSpacing.large),
        _SummaryRow(state: state),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1100;
            final board = _AssignmentsBoard(state: state);
            final timeline = _TimelinePanel(assignment: selected);
            if (compact) {
              return Column(
                children: [
                  board,
                  const SizedBox(height: AppSpacing.large),
                  timeline,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: board),
                const SizedBox(width: AppSpacing.large),
                Expanded(flex: 2, child: timeline),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.large),
        _HistoryTable(assignments: state.history),
      ],
    );
  }
}

class _AssignmentsHeader extends StatelessWidget {
  final FleetAssignmentsLoaded state;

  const _AssignmentsHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعيينات السائقين والمركبات',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'إسناد المركبات للسائقين، تغيير التعيين، إزالة التعيين، ومراجعة السجل التشغيلي.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: 'تعيين جديد',
            height: 40,
            onPressed: () => _showAssignmentDialog(context, state),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final FleetAssignmentsLoaded state;

  const _SummaryRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final unassignedVehicles =
        state.vehicles.length -
        state.activeAssignments
            .map((assignment) => assignment.vehicleId)
            .toSet()
            .length;
    final items = [
      ('تعيينات نشطة', '${state.activeAssignments.length}', Icons.link),
      ('سائقين متاحين', '${state.drivers.length}', Icons.badge_outlined),
      ('مركبات متاحة', '$unassignedVehicles', Icons.directions_bus_outlined),
      ('أحداث السجل', '${state.assignments.length}', Icons.timeline_outlined),
    ];

    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      children: items.map((item) {
        return SizedBox(
          width: 220,
          child: AppCard(
            child: Row(
              children: [
                Icon(item.$3),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$1),
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(
                        item.$2,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AssignmentsBoard extends StatelessWidget {
  final FleetAssignmentsLoaded state;

  const _AssignmentsBoard({required this.state});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التعيينات النشطة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.medium),
          if (state.activeAssignments.isEmpty)
            const Text('لا توجد تعيينات نشطة.')
          else
            ...state.activeAssignments.map(
              (assignment) => _AssignmentTile(
                assignment: assignment,
                selected: state.selectedAssignment?.id == assignment.id,
                state: state,
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final FleetAssignment assignment;
  final bool selected;
  final FleetAssignmentsLoaded state;

  const _AssignmentTile({
    required this.assignment,
    required this.selected,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          onTap: () => context.read<FleetAssignmentsCubit>().selectAssignment(
            assignment,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: selected
                      ? scheme.onPrimaryContainer
                      : scheme.primaryContainer,
                  child: Icon(
                    Icons.swap_horiz_outlined,
                    color: selected
                        ? scheme.primaryContainer
                        : scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${assignment.driverName} • ${assignment.vehiclePlate}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xSmall),
                      Text('${assignment.route} • منذ ${assignment.startedAt}'),
                    ],
                  ),
                ),
                Wrap(
                  spacing: AppSpacing.xSmall,
                  children: [
                    TextButton(
                      onPressed: () => _showAssignmentDialog(
                        context,
                        state,
                        assignment: assignment,
                      ),
                      child: const Text('تغيير'),
                    ),
                    TextButton(
                      onPressed: () => _showRemoveDialog(context, assignment),
                      child: const Text('إزالة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  final FleetAssignment? assignment;

  const _TimelinePanel({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final selected = assignment;
    if (selected == null) {
      return const AppCard(child: Text('اختر تعيين لعرض السجل الزمني.'));
    }
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('سجل التعيين', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xSmall),
          Text('${selected.driverName} • ${selected.vehiclePlate}'),
          const SizedBox(height: AppSpacing.medium),
          ...selected.timeline.indexed.map((entry) {
            final (index, event) = entry;
            final last = index == selected.timeline.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.check,
                        size: 15,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 58,
                        color: scheme.outline.withAlpha(120),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text('${event.date} • ${event.description}'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  final List<FleetAssignment> assignments;

  const _HistoryTable({required this.assignments});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('سجل التعيينات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          if (assignments.isEmpty)
            const Text('لا يوجد سجل سابق.')
          else
            ...assignments.map(
              (assignment) => ListTile(
                leading: const Icon(Icons.history_outlined),
                title: Text(
                  '${assignment.driverName} • ${assignment.vehiclePlate}',
                ),
                subtitle: Text(
                  '${assignment.route} • ${assignment.startedAt} - ${assignment.endedAt ?? 'حتى الآن'}',
                ),
                trailing: Text(assignment.status.label),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignmentsError extends StatelessWidget {
  final String message;

  const _AssignmentsError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.medium),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<FleetAssignmentsCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAssignmentDialog(
  BuildContext context,
  FleetAssignmentsLoaded state, {
  FleetAssignment? assignment,
}) {
  final cubit = context.read<FleetAssignmentsCubit>();
  var driverId = assignment?.driverId ?? state.drivers.first.id;
  var vehicleId = assignment?.vehicleId ?? state.vehicles.first.id;
  var route = assignment?.route ?? state.routes.first;
  var reason = assignment == null
      ? 'تعيين تشغيلي جديد'
      : 'تغيير احتياج التشغيل';

  showDialog<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(assignment == null ? 'تعيين مركبة' : 'تغيير التعيين'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: driverId,
                    decoration: const InputDecoration(labelText: 'السائق'),
                    items: state.drivers
                        .map(
                          (driver) => DropdownMenuItem(
                            value: driver.id,
                            child: Text('${driver.name} • ${driver.status}'),
                          ),
                        )
                        .toList(),
                    onChanged: assignment == null
                        ? (value) =>
                              setDialogState(() => driverId = value ?? driverId)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  DropdownButtonFormField<String>(
                    initialValue: vehicleId,
                    decoration: const InputDecoration(labelText: 'المركبة'),
                    items: state.vehicles
                        .map(
                          (vehicle) => DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(
                              '${vehicle.plateNumber} • ${vehicle.model}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => vehicleId = value ?? vehicleId),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  DropdownButtonFormField<String>(
                    initialValue: route,
                    decoration: const InputDecoration(labelText: 'المسار'),
                    items: state.routes
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => route = value ?? route),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  TextField(
                    decoration: const InputDecoration(labelText: 'سبب التعيين'),
                    minLines: 2,
                    maxLines: 3,
                    onChanged: (value) => reason = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  if (assignment == null) {
                    cubit.assignVehicle(
                      driverId: driverId,
                      vehicleId: vehicleId,
                      route: route,
                      reason: reason,
                    );
                  } else {
                    cubit.changeAssignment(
                      assignmentId: assignment.id,
                      vehicleId: vehicleId,
                      route: route,
                      reason: reason,
                    );
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

void _showRemoveDialog(BuildContext context, FleetAssignment assignment) {
  final cubit = context.read<FleetAssignmentsCubit>();
  var reason = 'إزالة التعيين بناءً على قرار التشغيل';

  showDialog<void>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إزالة التعيين'),
        content: SizedBox(
          width: 420,
          child: TextField(
            decoration: const InputDecoration(labelText: 'سبب الإزالة'),
            minLines: 2,
            maxLines: 3,
            onChanged: (value) => reason = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              cubit.removeAssignment(
                assignmentId: assignment.id,
                reason: reason,
              );
              Navigator.of(context).pop();
            },
            child: const Text('إزالة'),
          ),
        ],
      ),
    ),
  );
}
