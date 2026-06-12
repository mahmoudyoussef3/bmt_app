import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicles_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicles_card_list.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicle_details_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicle_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

enum _VehiclesViewState { list, details, form }

class FleetVehiclesScreen extends StatefulWidget {
  final ValueChanged<bool>? onViewStateChanged;
  const FleetVehiclesScreen({super.key, this.onViewStateChanged});

  @override
  State<FleetVehiclesScreen> createState() => _FleetVehiclesScreenState();
}

class _FleetVehiclesScreenState extends State<FleetVehiclesScreen> {
  _VehiclesViewState _viewState = _VehiclesViewState.list;
  FleetVehicle? _activeVehicle;
  int _page = 0;
  final int _pageSize = 8;
  FleetSortField _sortField = FleetSortField.name;
  bool _sortAscending = true;

  void _setView(_VehiclesViewState state, [FleetVehicle? vehicle]) {
    setState(() {
      _viewState = state;
      _activeVehicle = vehicle;
    });
    if (widget.onViewStateChanged != null) {
      widget.onViewStateChanged!(state == _VehiclesViewState.list);
    }
  }

  List<FleetVehicle> _sortVehicles(List<FleetVehicle> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final cmp = switch (_sortField) {
        FleetSortField.seats => a.seatsCount.compareTo(b.seatsCount),
        FleetSortField.modelYear => a.modelYear.compareTo(b.modelYear),
        FleetSortField.status => a.status.label.compareTo(b.status.label),
        _ => a.vehicleNumber.compareTo(b.vehicleNumber),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = context.watch<FleetOverviewCubit>().state;
    if (overviewState is! FleetOverviewLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final workspace = overviewState.workspace;

    return BlocBuilder<FleetVehiclesCubit, FleetVehiclesState>(
      builder: (context, state) {
        if (state is FleetVehiclesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FleetVehiclesError) {
          return Center(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.medium),
                  FilledButton(
                    onPressed: () => context.read<FleetVehiclesCubit>().load(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is FleetVehiclesLoaded) {
          final cubit = context.read<FleetVehiclesCubit>();
          final workspaceVehicles = state.filteredVehicles;
          final sorted = _sortVehicles(workspaceVehicles);

          switch (_viewState) {
            case _VehiclesViewState.details:
              if (_activeVehicle == null) {
                return const Text('حدث خطأ في عرض تفاصيل المركبة');
              }
              final updatedVehicle = state.vehicles.firstWhere(
                (v) => v.id == _activeVehicle!.id,
                orElse: () => _activeVehicle!,
              );
              return FleetVehicleDetailsView(
                vehicle: updatedVehicle,
                workspace: workspace,
                onBack: () => _setView(_VehiclesViewState.list),
                onEdit: () => _setView(_VehiclesViewState.form, updatedVehicle),
              );

            case _VehiclesViewState.form:
              return FleetVehicleFormView(
                vehicle: _activeVehicle,
                workspace: workspace,
                onBack: () => _setView(_VehiclesViewState.list),
                onSave: (savedVehicle) async {
                  await cubit.saveVehicle(savedVehicle);
                  if (context.mounted) {
                    await context.read<FleetOverviewCubit>().loadWorkspace();
                    _setView(_VehiclesViewState.list);
                  }
                },
              );

            case _VehiclesViewState.list:
            default:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(context, state, cubit),
                  const SizedBox(height: AppSpacing.medium),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 800;
                      if (isMobile) {
                        return FleetVehiclesCardList(
                          vehicles: sorted,
                          workspace: workspace,
                          onViewDetails: (v) => _setView(_VehiclesViewState.details, v),
                          onEdit: (v) => _setView(_VehiclesViewState.form, v),
                          page: _page,
                          pageSize: _pageSize,
                        );
                      } else {
                        return FleetVehiclesTable(
                          vehicles: sorted,
                          workspace: workspace,
                          onView: (v) => _setView(_VehiclesViewState.details, v),
                          onEdit: (v) => _setView(_VehiclesViewState.form, v),
                          selectedIds: state.selectedIds,
                          page: _page,
                          pageSize: _pageSize,
                          onPageChanged: (newPage) => setState(() => _page = newPage),
                        );
                      }
                    },
                  ),
                ],
              );
          }
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildToolbar(BuildContext context, FleetVehiclesLoaded state, FleetVehiclesCubit cubit) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              hintText: 'البحث برقم المركبة أو رقم اللوحة أو الموديل...',
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(scheme.surfaceContainerHighest.withAlpha(90)),
              onChanged: cubit.search,
              leading: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          DropdownButton<FleetSortField>(
            value: _sortField,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.sort_rounded),
            items: const [
              DropdownMenuItem(value: FleetSortField.name, child: Text('ترتيب حسب الكود')),
              DropdownMenuItem(value: FleetSortField.modelYear, child: Text('ترتيب حسب السنة')),
              DropdownMenuItem(value: FleetSortField.seats, child: Text('ترتيب بالمقاعد')),
              DropdownMenuItem(value: FleetSortField.status, child: Text('ترتيب حسب الحالة')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _sortField = val);
              }
            },
          ),
          IconButton(
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
            icon: Icon(_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
          ),
          const SizedBox(width: AppSpacing.small),
          if (state.selectedIds.isNotEmpty) ...[
            FilledButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('إيقاف تشغيل المركبات'),
                    content: Text('هل أنت متأكد من إيقاف ${state.selectedIds.length} من المركبات المحددة؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('إيقاف مؤقت'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await cubit.bulkSuspendVehicles();
                  if (context.mounted) {
                    await context.read<FleetOverviewCubit>().loadWorkspace();
                  }
                }
              },
              icon: const Icon(Icons.warning_amber_rounded),
              label: Text('إيقاف (${state.selectedIds.length})'),
              style: FilledButton.styleFrom(backgroundColor: scheme.error),
            ),
            const SizedBox(width: AppSpacing.small),
          ],
          FilledButton.icon(
            onPressed: () => _setView(_VehiclesViewState.form),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مركبة جديدة'),
          ),
        ],
      ),
    );
  }
}
