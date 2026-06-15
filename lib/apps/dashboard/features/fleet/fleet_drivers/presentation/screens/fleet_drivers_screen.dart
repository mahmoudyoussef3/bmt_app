import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_drivers_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_drivers_card_list.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_driver_details_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_driver_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

enum _DriversViewState { list, details, form }

class FleetDriversScreen extends StatefulWidget {
  final ValueChanged<bool>? onViewStateChanged;
  const FleetDriversScreen({super.key, this.onViewStateChanged});

  @override
  State<FleetDriversScreen> createState() => _FleetDriversScreenState();
}

class _FleetDriversScreenState extends State<FleetDriversScreen> {
  _DriversViewState _viewState = _DriversViewState.list;
  FleetDriver? _activeDriver;
  int _page = 0;
  final int _pageSize = 8;
  FleetSortField _sortField = FleetSortField.name;
  bool _sortAscending = true;

  void _setView(_DriversViewState state, [FleetDriver? driver]) {
    setState(() {
      _viewState = state;
      _activeDriver = driver;
    });
    if (widget.onViewStateChanged != null) {
      widget.onViewStateChanged!(state == _DriversViewState.list);
    }
  }

  List<FleetDriver> _sortDrivers(List<FleetDriver> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final cmp = switch (_sortField) {
        FleetSortField.licenseExpiry => a.licenseExpiry.compareTo(
          b.licenseExpiry,
        ),
        FleetSortField.status => a.status.label.compareTo(b.status.label),
        _ => a.name.compareTo(b.name),
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

    return BlocBuilder<FleetDriversCubit, FleetDriversState>(
      builder: (context, state) {
        if (state is FleetDriversLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FleetDriversError) {
          return Center(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  FilledButton(
                    onPressed: () => context.read<FleetDriversCubit>().load(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is FleetDriversLoaded) {
          final cubit = context.read<FleetDriversCubit>();
          final workspaceDrivers = state.filteredDrivers;
          final sorted = _sortDrivers(workspaceDrivers);

          switch (_viewState) {
            case _DriversViewState.details:
              if (_activeDriver == null) {
                return const Text('حدث خطأ في عرض تفاصيل السائق');
              }
              // Find latest driver state from workspace/state
              final updatedDriver = state.drivers.firstWhere(
                (d) => d.id == _activeDriver!.id,
                orElse: () => _activeDriver!,
              );
              return FleetDriverDetailsView(
                driver: updatedDriver,
                workspace: workspace,
                onBack: () => _setView(_DriversViewState.list),
                onEdit: () => _setView(_DriversViewState.form, updatedDriver),
              );

            case _DriversViewState.form:
              return FleetDriverFormView(
                driver: _activeDriver,
                workspace: workspace,
                onBack: () => _setView(_DriversViewState.list),
                onSave: (savedDriver) async {
                  await cubit.saveDriver(savedDriver);
                  // Refresh workspace as well
                  if (context.mounted) {
                    await context.read<FleetOverviewCubit>().loadWorkspace();
                    _setView(_DriversViewState.list);
                  }
                },
              );

            case _DriversViewState.list:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(context, state, cubit),
                  const SizedBox(height: AppSpacing.medium),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 800;
                      if (isMobile) {
                        return FleetDriversCardList(
                          drivers: sorted,
                          workspace: workspace,
                          onViewDetails: (d) =>
                              _setView(_DriversViewState.details, d),
                          onEdit: (d) => _setView(_DriversViewState.form, d),
                          page: _page,
                          pageSize: _pageSize,
                        );
                      } else {
                        return FleetDriversTable(
                          drivers: sorted,
                          workspace: workspace,
                          onView: (d) => _setView(_DriversViewState.details, d),
                          onEdit: (d) => _setView(_DriversViewState.form, d),
                          selectedIds: state.selectedIds,
                          page: _page,
                          pageSize: _pageSize,
                          onPageChanged: (newPage) =>
                              setState(() => _page = newPage),
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

  Widget _buildToolbar(
    BuildContext context,
    FleetDriversLoaded state,
    FleetDriversCubit cubit,
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
              hintText: 'البحث باسم السائق أو الرقم القومي أو الهاتف...',
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                scheme.surfaceContainerHighest.withAlpha(90),
              ),
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
              DropdownMenuItem(
                value: FleetSortField.name,
                child: Text('ترتيب حسب الاسم'),
              ),
              DropdownMenuItem(
                value: FleetSortField.status,
                child: Text('ترتيب حسب الحالة'),
              ),
              DropdownMenuItem(
                value: FleetSortField.licenseExpiry,
                child: Text('ترتيب بانتهاء الرخصة'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _sortField = val);
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
          ),
          const SizedBox(width: AppSpacing.small),
          if (state.selectedIds.isNotEmpty) ...[
            FilledButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('أرشفة السائقين'),
                    content: Text(
                      'هل أنت متأكد من أرشفة ${state.selectedIds.length} من السائقين المحددين؟',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('تأكيد الأرشفة'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await cubit.bulkArchiveDrivers();
                  if (context.mounted) {
                    await context.read<FleetOverviewCubit>().loadWorkspace();
                  }
                }
              },
              icon: const Icon(Icons.archive_outlined),
              label: Text('أرشفة (${state.selectedIds.length})'),
              style: FilledButton.styleFrom(backgroundColor: scheme.error),
            ),
            const SizedBox(width: AppSpacing.small),
          ],
          FilledButton.icon(
            onPressed: () => _setView(_DriversViewState.form),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة سائق جديد'),
          ),
        ],
      ),
    );
  }
}
