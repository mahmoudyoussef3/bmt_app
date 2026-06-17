import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_drivers_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_drivers_card_list.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_driver_details_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_driver_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/master_detail_layout.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/async_state_view.dart';

enum _DriversViewState { list, details, form }

enum _DriverOpsFilter {
  all('الكل'),
  available('متاح الآن'),
  assigned('معين'),
  needsAttention('يحتاج متابعة'),
  noVehicle('بدون مركبة'),
  suspended('موقوف');

  const _DriverOpsFilter(this.label);

  final String label;
}

class FleetDriversScreen extends StatefulWidget {
  final ValueChanged<bool>? onViewStateChanged;
  const FleetDriversScreen({super.key, this.onViewStateChanged});

  @override
  State<FleetDriversScreen> createState() => _FleetDriversScreenState();
}

class _FleetDriversScreenState extends State<FleetDriversScreen> {
  _DriversViewState _viewState = _DriversViewState.list;
  FleetDriver? _activeDriver;
  FleetDriver? _selectedDriver;
  int _page = 0;
  final int _pageSize = 8;
  FleetSortField _sortField = FleetSortField.name;
  bool _sortAscending = true;
  _DriverOpsFilter _opsFilter = _DriverOpsFilter.all;

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

  List<FleetDriver> _applyOperationsFilter(
    List<FleetDriver> drivers,
    FleetWorkspace workspace,
  ) {
    return drivers.where((driver) {
      final snapshot = DriverOperations.snapshot(driver, workspace);
      return switch (_opsFilter) {
        _DriverOpsFilter.all => true,
        _DriverOpsFilter.available => snapshot.canAssign,
        _DriverOpsFilter.assigned =>
          snapshot.status == DriverOperationalStatus.assigned,
        _DriverOpsFilter.needsAttention => snapshot.requiresAttention,
        _DriverOpsFilter.noVehicle => snapshot.assignedVehicle == null,
        _DriverOpsFilter.suspended =>
          driver.status == FleetDriverStatus.suspended,
      };
    }).toList();
  }

  /// Sets the sort field; tapping the active field flips direction.
  void _applySort(FleetSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  /// Opens a driver: side-by-side detail pane on desktop, full screen on narrow.
  void _openDriver(FleetDriver driver, bool isSplit) {
    if (isSplit) {
      setState(() => _selectedDriver = driver);
    } else {
      _setView(_DriversViewState.details, driver);
    }
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
        final status = switch (state) {
          FleetDriversLoading() => AsyncViewStatus.loading,
          FleetDriversError() => AsyncViewStatus.error,
          FleetDriversLoaded() => AsyncViewStatus.data,
        };

        return AsyncStateView(
          status: status,
          errorMessage: state is FleetDriversError
              ? state.message
              : 'تعذّر تحميل بيانات السائقين',
          onRetry: () => context.read<FleetDriversCubit>().load(),
          child: state is FleetDriversLoaded
              ? _buildLoaded(context, state, workspace)
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    FleetDriversLoaded state,
    FleetWorkspace workspace,
  ) {
    final cubit = context.read<FleetDriversCubit>();

    // The add/edit wizard takes over the full width in every breakpoint.
    if (_viewState == _DriversViewState.form) {
      return FleetDriverFormView(
        driver: _activeDriver,
        workspace: workspace,
        onBack: () => _setView(_DriversViewState.list),
        onSave: (savedDriver) async {
          await cubit.saveDriver(savedDriver);
          if (context.mounted) {
            await context.read<FleetOverviewCubit>().loadWorkspace();
            _setView(_DriversViewState.list);
          }
        },
      );
    }

    final sorted = _sortDrivers(
      _applyOperationsFilter(state.filteredDrivers, workspace),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplit = constraints.maxWidth >= AppLayout.breakpointTablet;

        // Narrow screens push a full-screen detail view (legacy behaviour).
        if (!isSplit &&
            _viewState == _DriversViewState.details &&
            _activeDriver != null) {
          return _detailsView(context, state, workspace, _activeDriver!,
              onBack: () => _setView(_DriversViewState.list));
        }

        final master = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(context, state, cubit, workspace),
            const SizedBox(height: AppSpacing.medium),
            _buildListBody(context, state, sorted, workspace, isSplit),
          ],
        );

        if (!isSplit) return master;

        // Desktop: keep the list in view alongside the readiness detail pane.
        final detail = _selectedDriver == null
            ? null
            : _detailsView(context, state, workspace, _selectedDriver!,
                onBack: () => setState(() => _selectedDriver = null));

        return MasterDetailLayout(
          master: master,
          detail: detail,
          placeholderTitle: 'اختر سائقاً لعرض الجاهزية',
          placeholderSubtitle:
              'حدد سائقاً من القائمة لمراجعة حالته التشغيلية وتفاصيله.',
        );
      },
    );
  }

  Widget _detailsView(
    BuildContext context,
    FleetDriversLoaded state,
    FleetWorkspace workspace,
    FleetDriver driver, {
    required VoidCallback onBack,
  }) {
    final updatedDriver = state.drivers.firstWhere(
      (d) => d.id == driver.id,
      orElse: () => driver,
    );
    return FleetDriverDetailsView(
      driver: updatedDriver,
      workspace: workspace,
      onBack: onBack,
      onEdit: () => _setView(_DriversViewState.form, updatedDriver),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    FleetDriversLoaded state,
    List<FleetDriver> sorted,
    FleetWorkspace workspace,
    bool isSplit,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCards = constraints.maxWidth < 800;
        if (useCards) {
          return FleetDriversCardList(
            drivers: sorted,
            workspace: workspace,
            onViewDetails: (d) => _openDriver(d, isSplit),
            onEdit: (d) => _setView(_DriversViewState.form, d),
            page: _page,
            pageSize: _pageSize,
          );
        }
        return FleetDriversTable(
          drivers: sorted,
          workspace: workspace,
          onView: (d) => _openDriver(d, isSplit),
          onEdit: (d) => _setView(_DriversViewState.form, d),
          selectedIds: state.selectedIds,
          selectedId: _selectedDriver?.id,
          page: _page,
          pageSize: _pageSize,
          onPageChanged: (newPage) => setState(() => _page = newPage),
          sortField: _sortField,
          sortAscending: _sortAscending,
          onSortField: _applySort,
        );
      },
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    FleetDriversLoaded state,
    FleetDriversCubit cubit,
    FleetWorkspace workspace,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReadinessSummary(context, state.drivers, workspace),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: _DriverOpsFilter.values.map((filter) {
              return FilterChip(
                selected: _opsFilter == filter,
                label: Text(filter.label),
                tooltip: 'تصفية السائقين حسب ${filter.label}',
                onSelected: (_) {
                  setState(() {
                    _opsFilter = filter;
                    _page = 0;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: SearchBar(
                  hintText: 'ابحث بالاسم أو كود الموظف أو الهاتف...',
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
              Tooltip(
                message: _sortAscending ? 'ترتيب تصاعدي' : 'ترتيب تنازلي',
                child: IconButton(
                  onPressed: () =>
                      setState(() => _sortAscending = !_sortAscending),
                  icon: Icon(
                    _sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                  ),
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
                        await context
                            .read<FleetOverviewCubit>()
                            .loadWorkspace();
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
                label: const Text('إضافة سائق'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessSummary(
    BuildContext context,
    List<FleetDriver> drivers,
    FleetWorkspace workspace,
  ) {
    final summaries = <_DriverSummaryItem>[
      _DriverSummaryItem(
        label: 'متاح الآن',
        value: drivers
            .where(
              (driver) =>
                  DriverOperations.snapshot(driver, workspace).canAssign,
            )
            .length,
        icon: Icons.task_alt_rounded,
      ),
      _DriverSummaryItem(
        label: 'معين لمركبة',
        value: drivers
            .where(
              (driver) =>
                  DriverOperations.snapshot(driver, workspace).status ==
                  DriverOperationalStatus.assigned,
            )
            .length,
        icon: Icons.directions_bus_filled_outlined,
      ),
      _DriverSummaryItem(
        label: 'يحتاج متابعة',
        value: drivers
            .where(
              (driver) => DriverOperations.snapshot(
                driver,
                workspace,
              ).requiresAttention,
            )
            .length,
        icon: Icons.warning_amber_rounded,
      ),
      _DriverSummaryItem(
        label: 'بدون مركبة',
        value: drivers
            .where(
              (driver) =>
                  DriverOperations.snapshot(
                    driver,
                    workspace,
                  ).assignedVehicle ==
                  null,
            )
            .length,
        icon: Icons.person_off_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: summaries
              .map(
                (item) => SizedBox(
                  width: isNarrow
                      ? (constraints.maxWidth - AppSpacing.small) / 2
                      : (constraints.maxWidth - AppSpacing.small * 3) / 4,
                  child: _DriverSummaryTile(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DriverSummaryItem {
  const _DriverSummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;
}

class _DriverSummaryTile extends StatelessWidget {
  const _DriverSummaryTile({required this.item});

  final _DriverSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: scheme.primary, size: 20),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Text(
            item.value.toString(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
