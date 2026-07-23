import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/cubit/fleet_assignments_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/cubit/fleet_assignments_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/widgets/fleet_assignments_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/widgets/fleet_assignments_card_list.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/widgets/fleet_assignment_dialog.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

class FleetAssignmentsScreen extends StatefulWidget {
  const FleetAssignmentsScreen({super.key});

  @override
  State<FleetAssignmentsScreen> createState() => _FleetAssignmentsScreenState();
}

class _FleetAssignmentsScreenState extends State<FleetAssignmentsScreen> {
  int _page = 0;
  final int _pageSize = 8;
  bool _sortAscending = true;

  List<FleetAssignment> _sortAssignments(List<FleetAssignment> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final cmp = a.assignedAt.compareTo(b.assignedAt);
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  void _openHistory(
    BuildContext context,
    String title,
    List<FleetHistoryItem> items,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.isEmpty
                  ? [const ListTile(title: Text('لا توجد سجلات تعيين سابقة.'))]
                  : items
                        .map(
                          (item) => ListTile(
                            title: Text(item.title),
                            subtitle: Text(
                              '${item.date} - ${item.description}',
                            ),
                          ),
                        )
                        .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _openAssignDialog(
    BuildContext context,
    FleetWorkspace workspace,
    FleetAssignmentsCubit cubit,
  ) {
    final activeDrivers = workspace.drivers
        .where(
          (driver) =>
              driver.status != FleetDriverStatus.archived &&
              driver.currentVehicleId.isEmpty,
        )
        .toList();

    final activeVehicles = workspace.vehicles
        .where(
          (vehicle) =>
              vehicle.status == FleetVehicleStatus.active &&
              vehicle.currentDriverId.isEmpty,
        )
        .toList();

    _openPairingDialog(
      context,
      cubit,
      workspace: workspace,
      drivers: activeDrivers,
      vehicles: activeVehicles,
    );
  }

  void _openReassignDialog(
    BuildContext context,
    FleetWorkspace workspace,
    FleetAssignmentsCubit cubit,
    FleetAssignment assignment,
  ) {
    final activeVehicles = workspace.vehicles
        .where(
          (vehicle) =>
              vehicle.status == FleetVehicleStatus.active &&
              vehicle.currentDriverId.isEmpty,
        )
        .toList();

    _openPairingDialog(
      context,
      cubit,
      workspace: workspace,
      assignment: assignment,
      vehicles: activeVehicles,
    );
  }

  void _openPairingDialog(
    BuildContext context,
    FleetAssignmentsCubit cubit, {
    required FleetWorkspace workspace,
    FleetAssignment? assignment,
    List<FleetDriver> drivers = const [],
    required List<FleetVehicle> vehicles,
  }) {
    final overviewCubit = context.read<FleetOverviewCubit>();
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: FleetAssignmentDialog(
          assignment: assignment,
          workspace: workspace,
          drivers: drivers,
          vehicles: vehicles,
        ),
      ),
    ).then((_) async {
      // Reload parent workspace state when assignment dialog is closed to reflect new assignments
      if (!mounted) return;
      await overviewCubit.loadWorkspace();
    });
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = context.watch<FleetOverviewCubit>().state;
    if (overviewState is! FleetOverviewLoaded) {
      return const DashboardLoading(showHeader: false, scrollable: false);
    }

    final workspace = overviewState.workspace;

    return BlocBuilder<FleetAssignmentsCubit, FleetAssignmentsState>(
      builder: (context, state) {
        if (state is FleetAssignmentsLoading) {
          return const DashboardLoading(showHeader: false, scrollable: false);
        }

        if (state is FleetAssignmentsError) {
          return DashboardErrorState(
            message: state.message,
            onRetry: () => context.read<FleetAssignmentsCubit>().load(),
          );
        }

        if (state is FleetAssignmentsLoaded) {
          final cubit = context.read<FleetAssignmentsCubit>();
          final sorted = _sortAssignments(state.filteredAssignments);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(context, state, cubit, workspace),
              const SizedBox(height: AppSpacing.medium),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 800;
                  if (isMobile) {
                    return FleetAssignmentsCardList(
                      assignments: sorted,
                      workspace: workspace,
                      page: _page,
                      pageSize: _pageSize,
                      onPageChanged: (newPage) =>
                          setState(() => _page = newPage),
                      onReassign: (a) =>
                          _openReassignDialog(context, workspace, cubit, a),
                      onViewHistory: (items) =>
                          _openHistory(context, 'سجل التعيين', items),
                    );
                  } else {
                    return FleetAssignmentsTable(
                      assignments: sorted,
                      workspace: workspace,
                      page: _page,
                      pageSize: _pageSize,
                      onPageChanged: (newPage) =>
                          setState(() => _page = newPage),
                      onReassign: (a) =>
                          _openReassignDialog(context, workspace, cubit, a),
                      onViewHistory: (items) =>
                          _openHistory(context, 'سجل التعيين', items),
                    );
                  }
                },
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    FleetAssignmentsLoaded state,
    FleetAssignmentsCubit cubit,
    FleetWorkspace workspace,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              hintText: 'البحث باسم السائق أو كود المركبة المعينة...',
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                scheme.surfaceContainerHighest.withAlpha(90),
              ),
              onChanged: cubit.search,
              leading: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          DropdownButton<String>(
            value: state.filter,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.filter_list_rounded),
            items: const [
              DropdownMenuItem(value: 'الكل', child: Text('جميع التعيينات')),
              DropdownMenuItem(value: 'نشط', child: Text('النشطة فقط')),
              DropdownMenuItem(value: 'منتهي', child: Text('المنتهية')),
            ],
            onChanged: (val) {
              if (val != null) {
                cubit.filter(val);
                setState(() => _page = 0);
              }
            },
          ),
          IconButton(
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
            icon: Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
            ),
            tooltip: 'ترتيب حسب تاريخ التعيين',
          ),
          const SizedBox(width: AppSpacing.small),
          FilledButton.icon(
            onPressed: () => _openAssignDialog(context, workspace, cubit),
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('تعيين جديد'),
          ),
        ],
      ),
    );
  }
}
