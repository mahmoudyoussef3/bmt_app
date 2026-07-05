import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicles_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicles_card_list.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicle_details_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicle_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/utils/fleet_pending_docs_uploader.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/master_detail_layout.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

enum _VehiclesViewState { list, details }

enum _VehicleOpsFilter {
  all('الكل'),
  active('نشطة'),
  assigned('مع سائق'),
  withoutDriver('بدون سائق'),
  documents('وثائق تحتاج متابعة'),
  maintenance('صيانة');

  const _VehicleOpsFilter(this.label);

  final String label;
}

class FleetVehiclesScreen extends StatefulWidget {
  final ValueChanged<bool>? onViewStateChanged;
  const FleetVehiclesScreen({super.key, this.onViewStateChanged});

  @override
  State<FleetVehiclesScreen> createState() => _FleetVehiclesScreenState();
}

class _FleetVehiclesScreenState extends State<FleetVehiclesScreen> {
  _VehiclesViewState _viewState = _VehiclesViewState.list;
  FleetVehicle? _activeVehicle;
  FleetVehicle? _selectedVehicle;
  int _page = 0;
  final int _pageSize = 8;
  FleetSortField _sortField = FleetSortField.name;
  bool _sortAscending = true;
  _VehicleOpsFilter _opsFilter = _VehicleOpsFilter.all;

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

  List<FleetVehicle> _applyOperationsFilter(List<FleetVehicle> vehicles) {
    return vehicles.where((vehicle) {
      return switch (_opsFilter) {
        _VehicleOpsFilter.all => true,
        _VehicleOpsFilter.active => vehicle.status == FleetVehicleStatus.active,
        _VehicleOpsFilter.assigned => vehicle.currentDriverId.isNotEmpty,
        _VehicleOpsFilter.withoutDriver => vehicle.currentDriverId.isEmpty,
        _VehicleOpsFilter.documents =>
          vehicle.hasExpiredDocument || vehicle.hasDocumentExpiringSoon,
        _VehicleOpsFilter.maintenance =>
          vehicle.status == FleetVehicleStatus.maintenance,
      };
    }).toList();
  }

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

  void _openVehicle(FleetVehicle vehicle, bool isSplit) {
    if (isSplit) {
      setState(() => _selectedVehicle = vehicle);
    } else {
      _setView(_VehiclesViewState.details, vehicle);
    }
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
          return const DashboardLoading(scrollable: false);
        }

        if (state is FleetVehiclesError) {
          return DashboardErrorState(
            title: 'تعذّر تحميل المركبات',
            message: state.message,
            onRetry: () => context.read<FleetVehiclesCubit>().load(),
          );
        }

        if (state is FleetVehiclesLoaded) {
          final cubit = context.read<FleetVehiclesCubit>();
          final sorted = _sortVehicles(
            _applyOperationsFilter(state.filteredVehicles),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isSplit =
                  constraints.maxWidth >= AppLayout.breakpointTablet;

              if (!isSplit &&
                  _viewState == _VehiclesViewState.details &&
                  _activeVehicle != null) {
                return _detailsView(
                  context,
                  state,
                  workspace,
                  _activeVehicle!,
                  cubit,
                  onBack: () => _setView(_VehiclesViewState.list),
                );
              }

              final master = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildReadinessSummary(context, state.vehicles),
                  const SizedBox(height: AppSpacing.large),
                  _buildToolbar(context, state, cubit, workspace),
                  const SizedBox(height: AppSpacing.medium),
                  _buildListBody(
                    context,
                    state,
                    sorted,
                    workspace,
                    cubit,
                    isSplit,
                  ),
                ],
              );

              if (!isSplit || _selectedVehicle == null) return master;

              final detail = _detailsView(
                context,
                state,
                workspace,
                _selectedVehicle!,
                cubit,
                onBack: () => setState(() => _selectedVehicle = null),
              );

              return MasterDetailLayout(
                master: master,
                detail: detail,
                placeholderTitle: 'اختر مركبة لعرض الجاهزية',
                placeholderSubtitle:
                    'حدد مركبة من القائمة لمراجعة السائق، الوثائق، والسعة.',
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _detailsView(
    BuildContext context,
    FleetVehiclesLoaded state,
    FleetWorkspace workspace,
    FleetVehicle vehicle,
    FleetVehiclesCubit cubit, {
    required VoidCallback onBack,
  }) {
    final updatedVehicle = state.vehicles.firstWhere(
      (v) => v.id == vehicle.id,
      orElse: () => vehicle,
    );
    return FleetVehicleDetailsView(
      vehicle: updatedVehicle,
      workspace: workspace,
      onBack: onBack,
      onEdit: () => _showVehicleForm(context, cubit, workspace, updatedVehicle),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    FleetVehiclesLoaded state,
    List<FleetVehicle> sorted,
    FleetWorkspace workspace,
    FleetVehiclesCubit cubit,
    bool isSplit,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCards = isSplit || constraints.maxWidth < 1200;
        if (useCards) {
          return FleetVehiclesCardList(
            vehicles: sorted,
            workspace: workspace,
            onViewDetails: (v) => _openVehicle(v, isSplit),
            onEdit: (v) => _showVehicleForm(context, cubit, workspace, v),
            onDelete: _confirmDeleteVehicle,
            page: _page,
            pageSize: _pageSize,
            onPageChanged: (newPage) => setState(() => _page = newPage),
          );
        }

        return FleetVehiclesTable(
          vehicles: sorted,
          workspace: workspace,
          onView: (v) => _openVehicle(v, isSplit),
          onEdit: (v) => _showVehicleForm(context, cubit, workspace, v),
          selectedIds: state.selectedIds,
          page: _page,
          pageSize: _pageSize,
          onPageChanged: (newPage) => setState(() => _page = newPage),
        );
      },
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    FleetVehiclesLoaded state,
    FleetVehiclesCubit cubit,
    FleetWorkspace workspace,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _VehicleFilterBar(
                  selected: _opsFilter,
                  onSelected: (filter) {
                    setState(() {
                      _opsFilter = filter;
                      _page = 0;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            FilledButton.icon(
              onPressed: () =>
                  _showVehicleForm(context, cubit, workspace, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة مركبة'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        _VehicleSearchSortActions(
          selectedCount: state.selectedIds.length,
          sortField: _sortField,
          sortAscending: _sortAscending,
          onSearch: cubit.search,
          onSortChanged: _applySort,
          onToggleSort: () => setState(() => _sortAscending = !_sortAscending),
          onSuspend: state.selectedIds.isEmpty
              ? null
              : () async {
                  final scheme = Theme.of(context).colorScheme;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('إيقاف تشغيل المركبات'),
                      content: Text(
                        'هل أنت متأكد من إيقاف ${state.selectedIds.length} من المركبات المحددة؟',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.error,
                          ),
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
        ),
      ],
    );
  }

  Widget _buildReadinessSummary(
    BuildContext context,
    List<FleetVehicle> vehicles,
  ) {
    final summaries = <_VehicleSummaryItem>[
      _VehicleSummaryItem(
        label: 'نشطة',
        value: vehicles
            .where((vehicle) => vehicle.status == FleetVehicleStatus.active)
            .length,
        icon: Icons.task_alt_rounded,
      ),
      _VehicleSummaryItem(
        label: 'مع سائق',
        value: vehicles
            .where((vehicle) => vehicle.currentDriverId.isNotEmpty)
            .length,
        icon: Icons.badge_outlined,
      ),
      _VehicleSummaryItem(
        label: 'بدون سائق',
        value: vehicles
            .where((vehicle) => vehicle.currentDriverId.isEmpty)
            .length,
        icon: Icons.person_off_outlined,
      ),
      _VehicleSummaryItem(
        label: 'وثائق تحتاج متابعة',
        value: vehicles
            .where(
              (vehicle) =>
                  vehicle.hasExpiredDocument || vehicle.hasDocumentExpiringSoon,
            )
            .length,
        icon: Icons.warning_amber_rounded,
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
                  child: _VehicleSummaryTile(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _showVehicleForm(
    BuildContext context,
    FleetVehiclesCubit cubit,
    FleetWorkspace workspace,
    FleetVehicle? vehicle,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return FleetVehicleFormView(
          vehicle: vehicle,
          workspace: workspace,
          onBack: () => Navigator.pop(dialogContext),
          onSave: (savedVehicle, pendingDocs) async {
            final docsCubit = context.read<FleetDocumentsCubit>();
            final overviewCubit = context.read<FleetOverviewCubit>();
            final isEdit = savedVehicle.id.isNotEmpty;
            try {
              final saved = await cubit.saveVehicle(savedVehicle);

              final failed = await FleetPendingDocsUploader.upload(
                docsCubit,
                ownerId: saved.id,
                isDriver: false,
                docs: pendingDocs,
              );

              if (dialogContext.mounted) Navigator.pop(dialogContext);

              if (context.mounted) {
                if (failed.isEmpty) {
                  AppSnackbar.success(
                    context,
                    isEdit
                        ? 'تم حفظ تعديلات المركبة بنجاح'
                        : 'تمت إضافة المركبة بنجاح',
                  );
                } else {
                  AppSnackbar.warning(
                    context,
                    'تم حفظ المركبة، لكن تعذّر رفع: ${failed.join('، ')}',
                  );
                }
              }

              await overviewCubit.loadWorkspace();
              return null;
            } catch (error) {
              // Keep the dialog open so the user can fix the data and retry.
              return error.toString().replaceAll('Exception: ', '');
            }
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteVehicle(FleetVehicle vehicle) async {
    final vehiclesCubit = context.read<FleetVehiclesCubit>();
    final overviewCubit = context.read<FleetOverviewCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المركبة نهائياً'),
        content: Text(
          'سيتم حذف المركبة "${vehicle.vehicleNumber}" من قاعدة البيانات مع وثائقها وتعييناتها. لا يمكن التراجع عن هذا الإجراء.',
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
    if (confirmed != true || !mounted) return;
    if (_selectedVehicle?.id == vehicle.id) {
      setState(() => _selectedVehicle = null);
    }
    final error = await vehiclesCubit.deleteVehicle(vehicle.id);
    if (!mounted) return;
    if (error == null) {
      AppSnackbar.success(context, 'تم حذف المركبة "${vehicle.vehicleNumber}"');
      await overviewCubit.loadWorkspace();
    } else {
      AppSnackbar.error(context, error);
    }
  }
}

class _VehicleFilterBar extends StatelessWidget {
  const _VehicleFilterBar({required this.selected, required this.onSelected});

  final _VehicleOpsFilter selected;
  final ValueChanged<_VehicleOpsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: _VehicleOpsFilter.values.map((filter) {
        final isSelected = selected == filter;
        return ChoiceChip(
          selected: isSelected,
          label: Text(filter.label),
          showCheckmark: false,
          avatar: isSelected ? const Icon(Icons.check_rounded, size: 16) : null,
          tooltip: 'تصفية المركبات حسب ${filter.label}',
          onSelected: (_) => onSelected(filter),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}

class _VehicleSearchSortActions extends StatelessWidget {
  const _VehicleSearchSortActions({
    required this.selectedCount,
    required this.sortField,
    required this.sortAscending,
    required this.onSearch,
    required this.onSortChanged,
    required this.onToggleSort,
    required this.onSuspend,
  });

  final int selectedCount;
  final FleetSortField sortField;
  final bool sortAscending;
  final ValueChanged<String> onSearch;
  final ValueChanged<FleetSortField> onSortChanged;
  final VoidCallback onToggleSort;
  final VoidCallback? onSuspend;

  String get _sortLabel {
    return switch (sortField) {
      FleetSortField.modelYear => 'سنة الموديل',
      FleetSortField.seats => 'المقاعد',
      FleetSortField.status => 'الحالة',
      _ => 'الكود',
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;
        final search = _VehicleSearchField(onChanged: onSearch);
        final controls = _VehicleSortActions(
          selectedCount: selectedCount,
          sortField: sortField,
          sortAscending: sortAscending,
          sortLabel: _sortLabel,
          onSortChanged: onSortChanged,
          onToggleSort: onToggleSort,
          onSuspend: onSuspend,
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: AppSpacing.small),
              controls,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: AppSpacing.medium),
            controls,
          ],
        );
      },
    );
  }
}

class _VehicleSearchField extends StatelessWidget {
  const _VehicleSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SearchBar(
      hintText: 'البحث برقم المركبة أو رقم اللوحة أو الموديل...',
      elevation: WidgetStateProperty.all(0),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      ),
      backgroundColor: WidgetStateProperty.all(
        scheme.surfaceContainerHighest.withAlpha(90),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onChanged: onChanged,
      leading: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
    );
  }
}

class _VehicleSortActions extends StatelessWidget {
  const _VehicleSortActions({
    required this.selectedCount,
    required this.sortField,
    required this.sortAscending,
    required this.sortLabel,
    required this.onSortChanged,
    required this.onToggleSort,
    required this.onSuspend,
  });

  final int selectedCount;
  final FleetSortField sortField;
  final bool sortAscending;
  final String sortLabel;
  final ValueChanged<FleetSortField> onSortChanged;
  final VoidCallback onToggleSort;
  final VoidCallback? onSuspend;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MenuAnchor(
          builder: (context, controller, child) {
            return OutlinedButton.icon(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: const Icon(Icons.sort_rounded),
              label: Text('ترتيب: $sortLabel'),
            );
          },
          menuChildren: [
            MenuItemButton(
              onPressed: () => onSortChanged(FleetSortField.name),
              leadingIcon: sortField == FleetSortField.name
                  ? const Icon(Icons.check_rounded)
                  : null,
              child: const Text('الكود'),
            ),
            MenuItemButton(
              onPressed: () => onSortChanged(FleetSortField.modelYear),
              leadingIcon: sortField == FleetSortField.modelYear
                  ? const Icon(Icons.check_rounded)
                  : null,
              child: const Text('سنة الموديل'),
            ),
            MenuItemButton(
              onPressed: () => onSortChanged(FleetSortField.seats),
              leadingIcon: sortField == FleetSortField.seats
                  ? const Icon(Icons.check_rounded)
                  : null,
              child: const Text('المقاعد'),
            ),
            MenuItemButton(
              onPressed: () => onSortChanged(FleetSortField.status),
              leadingIcon: sortField == FleetSortField.status
                  ? const Icon(Icons.check_rounded)
                  : null,
              child: const Text('الحالة'),
            ),
          ],
        ),
        Tooltip(
          message: sortAscending ? 'ترتيب تصاعدي' : 'ترتيب تنازلي',
          child: IconButton.outlined(
            onPressed: onToggleSort,
            icon: Icon(
              sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
            ),
          ),
        ),
        if (selectedCount > 0)
          FilledButton.tonalIcon(
            onPressed: onSuspend,
            icon: const Icon(Icons.pause_circle_outline_rounded),
            label: Text('إيقاف $selectedCount'),
          ),
      ],
    );
  }
}

class _VehicleSummaryItem {
  const _VehicleSummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;
}

class _VehicleSummaryTile extends StatelessWidget {
  const _VehicleSummaryTile({required this.item});

  final _VehicleSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withAlpha(70)),
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
