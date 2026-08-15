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
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/utils/fleet_pending_docs_uploader.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/async_state_view.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/theme/tokens.dart';

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
  int _page = 0;
  final int _pageSize = 8;
  FleetSortField _sortField = FleetSortField.name;
  bool _sortAscending = true;
  _DriverOpsFilter _opsFilter = _DriverOpsFilter.all;

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

  void _openDriver(
    BuildContext context,
    FleetDriversLoaded state,
    FleetWorkspace workspace,
    FleetDriver driver,
    FleetDriversCubit cubit,
    bool isDesktop,
  ) {
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          ),
          child: SizedBox(
            width: 800,
            height: 800,
            child: _detailsView(
              context,
              state,
              workspace,
              driver,
              cubit,
              onBack: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (context, controller) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: _detailsView(
                    context,
                    state,
                    workspace,
                    driver,
                    cubit,
                    onBack: () => Navigator.pop(context),
                    scrollController: controller,
                  ),
                ),
              ],
            );
          },
        ),
      );
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
          loadingPlaceholder: const DashboardLoading(scrollable: false),
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

    final sorted = _sortDrivers(
      _applyOperationsFilter(state.filteredDrivers, workspace),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppLayout.breakpointTablet;

        final browsing = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReadinessSummary(context, state.drivers, workspace),
            const SizedBox(height: AppSpacing.large),
            _buildToolbar(context, state, cubit, workspace),
            const SizedBox(height: AppSpacing.medium),
            _buildListBody(context, state, sorted, workspace, cubit, isDesktop),
          ],
        );

        return constraints.maxHeight.isFinite
            ? SingleChildScrollView(child: browsing)
            : browsing;
      },
    );
  }

  Widget _detailsView(
    BuildContext context,
    FleetDriversLoaded state,
    FleetWorkspace workspace,
    FleetDriver driver,
    FleetDriversCubit cubit, {
    required VoidCallback onBack,
    ScrollController? scrollController,
  }) {
    final updatedDriver = state.drivers.firstWhere(
      (d) => d.id == driver.id,
      orElse: () => driver,
    );
    return FleetDriverDetailsView(
      driver: updatedDriver,
      workspace: workspace,
      onBack: onBack,
      onEdit: () => _showDriverForm(context, cubit, workspace, updatedDriver),
      scrollController: scrollController,
    );
  }

  Widget _buildListBody(
    BuildContext context,
    FleetDriversLoaded state,
    List<FleetDriver> sorted,
    FleetWorkspace workspace,
    FleetDriversCubit cubit,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCards = !isDesktop || constraints.maxWidth < 1200;
        if (useCards) {
          return FleetDriversCardList(
            drivers: sorted,
            workspace: workspace,
            onViewDetails: (d) => _openDriver(context, state, workspace, d, cubit, isDesktop),
            onEdit: (d) => _showDriverForm(context, cubit, workspace, d),
            onDelete: _confirmDeleteDriver,
            page: _page,
            pageSize: _pageSize,
            onPageChanged: (newPage) => setState(() => _page = newPage),
          );
        }
        return FleetDriversTable(
          drivers: sorted,
          workspace: workspace,
          onView: (d) => _openDriver(context, state, workspace, d, cubit, isDesktop),
          onEdit: (d) => _showDriverForm(context, cubit, workspace, d),
          selectedIds: state.selectedIds,
          selectedId: null,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _DriverFilterBar(
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
              onPressed: () => _showDriverForm(context, cubit, workspace, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة سائق'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        _DriverSearchSortActions(
          selectedCount: state.selectedIds.length,
          sortField: _sortField,
          sortAscending: _sortAscending,
          onSearch: cubit.search,
          onSortChanged: (field) => setState(() => _sortField = field),
          onToggleSort: () => setState(() => _sortAscending = !_sortAscending),
          onArchive: state.selectedIds.isEmpty
              ? null
              : () async {
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
        ),
      ],
    );
  }

  void _showDriverForm(
    BuildContext context,
    FleetDriversCubit cubit,
    FleetWorkspace workspace,
    FleetDriver? driver,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return FleetDriverFormView(
          driver: driver,
          workspace: workspace,
          onBack: () => Navigator.pop(dialogContext),
          onSave: (savedDriver, pendingDocs) async {
            final docsCubit = context.read<FleetDocumentsCubit>();
            final overviewCubit = context.read<FleetOverviewCubit>();
            final isEdit = savedDriver.id.isNotEmpty;
            try {
              final saved = await cubit.saveDriver(savedDriver);

              final failed = await FleetPendingDocsUploader.upload(
                docsCubit,
                ownerId: saved.id,
                isDriver: true,
                docs: pendingDocs,
              );

              if (dialogContext.mounted) Navigator.pop(dialogContext);

              if (context.mounted) {
                if (failed.isEmpty) {
                  AppSnackbar.success(
                    context,
                    isEdit
                        ? 'تم حفظ تعديلات السائق بنجاح'
                        : 'تمت إضافة السائق بنجاح',
                  );
                } else {
                  AppSnackbar.warning(
                    context,
                    'تم حفظ السائق، لكن تعذّر رفع: ${failed.join('، ')}',
                  );
                }
              }

              await overviewCubit.loadWorkspace();
              return null;
            } catch (error) {
              return error.toString().replaceAll('Exception: ', '');
            }
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteDriver(FleetDriver driver) async {
    final driversCubit = context.read<FleetDriversCubit>();
    final overviewCubit = context.read<FleetOverviewCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السائق نهائياً'),
        content: Text(
          'سيتم حذف السائق "${driver.name}" من قاعدة البيانات مع وثائقه وتعييناته. لا يمكن التراجع عن هذا الإجراء.',
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
    final error = await driversCubit.deleteDriver(driver.id);
    if (!mounted) return;
    if (error == null) {
      AppSnackbar.success(context, 'تم حذف السائق "${driver.name}"');
      await overviewCubit.loadWorkspace();
    } else {
      AppSnackbar.error(context, error);
    }
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

class _DriverFilterBar extends StatelessWidget {
  const _DriverFilterBar({required this.selected, required this.onSelected});

  final _DriverOpsFilter selected;
  final ValueChanged<_DriverOpsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      alignment: WrapAlignment.start,
      children: _DriverOpsFilter.values.map((filter) {
        final isSelected = selected == filter;
        return ChoiceChip(
          selected: isSelected,
          label: Text(filter.label),
          showCheckmark: false,
          avatar: isSelected ? const Icon(Icons.check_rounded, size: 16) : null,
          tooltip: 'تصفية السائقين حسب ${filter.label}',
          onSelected: (_) => onSelected(filter),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          ),
        );
      }).toList(),
    );
  }
}

class _DriverSearchSortActions extends StatelessWidget {
  const _DriverSearchSortActions({
    required this.selectedCount,
    required this.sortField,
    required this.sortAscending,
    required this.onSearch,
    required this.onSortChanged,
    required this.onToggleSort,
    required this.onArchive,
  });

  final int selectedCount;
  final FleetSortField sortField;
  final bool sortAscending;
  final ValueChanged<String> onSearch;
  final ValueChanged<FleetSortField> onSortChanged;
  final VoidCallback onToggleSort;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;
        final search = _DriverSearchField(onChanged: onSearch);
        final controls = _DriverSortActions(
          selectedCount: selectedCount,
          sortField: sortField,
          sortAscending: sortAscending,
          onSortChanged: onSortChanged,
          onToggleSort: onToggleSort,
          onArchive: onArchive,
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

class _DriverSearchField extends StatelessWidget {
  const _DriverSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DebouncedSearchField(
      hintText: 'ابحث بالاسم، الكود، أو رقم الهاتف...',
      onChanged: onChanged,
    );
  }
}

class _DriverSortActions extends StatelessWidget {
  const _DriverSortActions({
    required this.selectedCount,
    required this.sortField,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onToggleSort,
    required this.onArchive,
  });

  final int selectedCount;
  final FleetSortField sortField;
  final bool sortAscending;
  final ValueChanged<FleetSortField> onSortChanged;
  final VoidCallback onToggleSort;
  final VoidCallback? onArchive;

  String get _sortLabel {
    return switch (sortField) {
      FleetSortField.status => 'الحالة',
      FleetSortField.licenseExpiry => 'انتهاء الرخصة',
      _ => 'الاسم',
    };
  }

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
              label: Text('ترتيب: $_sortLabel'),
            );
          },
          menuChildren: [
            MenuItemButton(
              onPressed: () => onSortChanged(FleetSortField.name),
              leadingIcon: sortField == FleetSortField.name
                  ? const Icon(Icons.check_rounded)
                  : null,
              child: const Text('الاسم'),
            ),
            MenuItemButton(
              onPressed: () => onSortChanged(FleetSortField.status),
              leadingIcon: sortField == FleetSortField.status
                  ? const Icon(Icons.check_rounded)
                  : null,
              child: const Text('الحالة'),
            ),
            MenuItemButton(
              onPressed: () => onSortChanged(FleetSortField.licenseExpiry),
              leadingIcon: sortField == FleetSortField.licenseExpiry
                  ? const Icon(Icons.check_rounded)
                  : null,
              child: const Text('انتهاء الرخصة'),
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
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined),
            label: Text('أرشفة $selectedCount'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radius),
              ),
            ),
          ),
      ],
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
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: scheme.outlineVariant.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
