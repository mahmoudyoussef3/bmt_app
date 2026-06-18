import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

/// Sortable column indices exposed by the drivers table header. Kept in one
/// place so the screen and the table agree on the column→field mapping.
const int _kDriverCol = 1;
const int _kLicenseCol = 5;

class FleetDriversTable extends StatelessWidget {
  final List<FleetDriver> drivers;
  final FleetWorkspace workspace;
  final ValueChanged<FleetDriver> onView;
  final ValueChanged<FleetDriver> onEdit;
  final Set<String> selectedIds;
  final String? selectedId;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final FleetSortField sortField;
  final bool sortAscending;
  final ValueChanged<FleetSortField> onSortField;

  const FleetDriversTable({
    super.key,
    required this.drivers,
    required this.workspace,
    required this.onView,
    required this.onEdit,
    required this.selectedIds,
    this.selectedId,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.sortField,
    required this.sortAscending,
    required this.onSortField,
  });

  String _vehicleName(String vehicleId) {
    if (vehicleId.isEmpty) return '';
    final match = workspace.vehicles.where((v) => v.id == vehicleId);
    if (match.isEmpty) return '';
    return match.first.vehicleNumber;
  }

  static (Color bg, Color fg) _healthColors(DriverHealthLevel health) =>
      switch (health) {
        DriverHealthLevel.healthy => (
          AppStatusColors.successContainer,
          AppStatusColors.onSuccessContainer,
        ),
        DriverHealthLevel.warning => (
          AppStatusColors.warningContainer,
          AppStatusColors.onWarningContainer,
        ),
        DriverHealthLevel.critical => (
          AppStatusColors.errorContainer,
          AppStatusColors.onErrorContainer,
        ),
      };

  int? get _sortColumnIndex => switch (sortField) {
    FleetSortField.name => _kDriverCol,
    FleetSortField.licenseExpiry => _kLicenseCol,
    _ => null,
  };

  void _handleSort(int index) {
    final field = switch (index) {
      _kDriverCol => FleetSortField.name,
      _kLicenseCol => FleetSortField.licenseExpiry,
      _ => null,
    };
    if (field != null) onSortField(field);
  }

  static Future<void> _archiveWithConfirmation(
    BuildContext context,
    FleetDriver driver,
    FleetDriversCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الأرشفة'),
        content: Text(
          'هل تريد أرشفة السائق "${driver.name}"؟\n'
          'لن يظهر في القوائم العادية ويمكن استعادته لاحقاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('أرشفة'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      cubit.updateDriverStatus(driver.id, FleetDriverStatus.archived);
    }
  }

  static Future<void> _deleteWithConfirmation(
    BuildContext context,
    FleetDriver driver,
    FleetDriversCubit cubit,
  ) async {
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
    if (confirmed == true) {
      cubit.deleteDriver(driver.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetDriversCubit>();
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, drivers.length);
    final paged = start >= drivers.length
        ? <FleetDriver>[]
        : drivers.sublist(start, end);

    return OpsDataTable(
      total: drivers.length,
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      sortColumnIndex: _sortColumnIndex,
      sortDirection: sortAscending ? OpsSort.asc : OpsSort.desc,
      onSort: _handleSort,
      columns: const [
        OpsColumn('تحديد', flex: 1, minWidth: 64),
        OpsColumn('السائق', flex: 4, sortable: true, minWidth: 240),
        OpsColumn('الصحة', flex: 2, minWidth: 116),
        OpsColumn('التوفر', flex: 2, minWidth: 120),
        OpsColumn('المركبة', flex: 2, minWidth: 120),
        OpsColumn('الرخصة', flex: 2, sortable: true, minWidth: 132),
        OpsColumn('إجراءات', flex: 2, minWidth: 112),
      ],
      rows: paged.map((driver) {
        final vehicle = _vehicleName(driver.currentVehicleId);
        final snapshot = DriverOperations.snapshot(driver, workspace);
        final (healthBg, healthFg) = _healthColors(snapshot.health);
        return [
          Checkbox(
            value: selectedIds.contains(driver.id),
            onChanged: (_) => cubit.toggleSelection(driver.id),
          ),
          _DriverIdentityCell(
            driver: driver,
            selected: driver.id == selectedId,
          ),
          Tooltip(
            message: snapshot.primaryReason,
            child: StatusChip(
              label: snapshot.health.label,
              color: healthBg,
              textColor: healthFg,
            ),
          ),
          StatusChip(label: snapshot.status.label),
          Text(vehicle.isEmpty ? 'بدون مركبة' : vehicle),
          Text(
            driver.licenseExpiry,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _DriverRowActions(
            driver: driver,
            onView: () => onView(driver),
            onEdit: () => onEdit(driver),
            cubit: cubit,
          ),
        ];
      }).toList(),
    );
  }
}

class _DriverIdentityCell extends StatelessWidget {
  final FleetDriver driver;
  final bool selected;

  const _DriverIdentityCell({required this.driver, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FleetAvatar(
          label: driver.imageLabel,
          profileImageUrl: driver.profileImageUrl,
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              Text(
                driver.phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverRowActions extends StatelessWidget {
  final FleetDriver driver;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final FleetDriversCubit cubit;

  const _DriverRowActions({
    required this.driver,
    required this.onView,
    required this.onEdit,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'عرض جاهزية السائق',
          onPressed: onView,
          icon: const Icon(Icons.visibility_outlined),
        ),
        IconButton(
          tooltip: 'تعديل بيانات السائق',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        PopupMenuButton<String>(
          tooltip: 'المزيد من الإجراءات',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'suspend') {
              cubit.updateDriverStatus(driver.id, FleetDriverStatus.suspended);
            } else if (value == 'activate') {
              cubit.updateDriverStatus(driver.id, FleetDriverStatus.active);
            } else if (value == 'archive') {
              FleetDriversTable._archiveWithConfirmation(
                context,
                driver,
                cubit,
              );
            } else if (value == 'delete') {
              FleetDriversTable._deleteWithConfirmation(context, driver, cubit);
            }
          },
          itemBuilder: (ctx) => [
            if (driver.status == FleetDriverStatus.active)
              const PopupMenuItem(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.pause_circle_outline_rounded),
                    SizedBox(width: AppSpacing.small),
                    Text('إيقاف السائق'),
                  ],
                ),
              ),
            if (driver.status == FleetDriverStatus.suspended)
              const PopupMenuItem(
                value: 'activate',
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded),
                    SizedBox(width: AppSpacing.small),
                    Text('تفعيل السائق'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(
                    Icons.archive_outlined,
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    'أرشفة السائق',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
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
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
