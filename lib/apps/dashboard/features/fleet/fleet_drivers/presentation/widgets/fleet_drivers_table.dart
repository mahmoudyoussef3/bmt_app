import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_drivers_toolbar.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_format.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// Sortable column indices exposed by the drivers table header. Kept in one
/// place so the screen and the table agree on the column→field mapping.
const int _kDriverCol = 1;
const int _kLicenseCol = 5;

/// السائقون, as a table.
///
/// ## The column budget
///
/// Every column declares a minimum width, and [OpsDataTable] scrolls sideways
/// the moment they add up to more than the pane. The nine columns this used to
/// declare summed to 1184px while the list only drops to cards below
/// [kDashboardTableBreakpoint] (1040) — so on any console narrower than a
/// 1440px screen *with the sidebar collapsed*, the fleet list was permanently
/// scrolled sideways, and the actions column lived off-screen.
///
/// The set below sums to 946px, which leaves room for the table's own padding
/// and inter-column gaps inside 1040. Two columns paid for it: "الصحة" and
/// "التوفر" were one answer printed twice (see [FleetStatusReasonCell]), and
/// the flexes are kept proportional to the minimums so a column never gets a
/// share of a wide table that is narrower than the minimum it asked for.
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
  final FleetDriverSort sort;
  final bool sortAscending;
  final ValueChanged<FleetDriverSort> onSort;

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
    required this.sort,
    required this.sortAscending,
    required this.onSort,
  });

  String _vehicleName(String vehicleId) {
    if (vehicleId.isEmpty) return '';
    final match = workspace.vehicles.where((v) => v.id == vehicleId);
    if (match.isEmpty) return '';
    return match.first.vehicleNumber;
  }

  /// The semantic status role a driver's health level maps to. Returning a
  /// tone rather than a colour pair is what lets the caller resolve it against
  /// the theme in effect — these used to be light-only constants.
  static AppStatusTone _healthTone(DriverHealthLevel health) =>
      switch (health) {
        DriverHealthLevel.healthy => AppStatusTone.success,
        DriverHealthLevel.warning => AppStatusTone.warning,
        DriverHealthLevel.critical => AppStatusTone.error,
      };

  int? get _sortColumnIndex => switch (sort) {
    FleetDriverSort.name => _kDriverCol,
    FleetDriverSort.licenseExpiry => _kLicenseCol,
  };

  void _handleSort(int index) {
    final field = switch (index) {
      _kDriverCol => FleetDriverSort.name,
      _kLicenseCol => FleetDriverSort.licenseExpiry,
      _ => null,
    };
    if (field != null) onSort(field);
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
    if (confirmed != true) return;
    final error = await cubit.deleteDriver(driver.id);
    if (!context.mounted) return;
    if (error == null) {
      AppSnackbar.success(context, 'تم حذف السائق "${driver.name}"');
    } else {
      AppSnackbar.error(context, error);
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
    final suspendedTint = context.status(AppStatusTone.error).tint;

    return OpsDataTable(
      total: drivers.length,
      totalLabel: 'الإجمالي ${FleetFormat.count(drivers.length)} سائق',
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      sortColumnIndex: _sortColumnIndex,
      sortDirection: sortAscending ? OpsSort.asc : OpsSort.desc,
      onSort: _handleSort,
      // The whole row opens the driver's file — the same thing the eye icon
      // does, without having to travel to the end of the row for it.
      onRowTap: [for (final driver in paged) () => onView(driver)],
      rowTints: [
        for (final driver in paged)
          driver.status == FleetDriverStatus.suspended ? suspendedTint : null,
      ],
      emptyState: const DashboardEmptyState(
        icon: DashboardIcons.captains,
        title: 'لا يوجد سائقون مطابقون',
        message:
            'لا يطابق أي سائق البحث أو الفلاتر الحالية. وسّع الفلاتر، أو أضف '
            'سائقاً جديداً إلى الأسطول.',
      ),
      columns: const [
        OpsColumn('تحديد', flex: 2, minWidth: 44),
        OpsColumn('السائق', flex: 10, sortable: true, minWidth: 220),
        OpsColumn('الجاهزية', flex: 6, minWidth: 132),
        OpsColumn('المركبة', flex: 4, minWidth: 88),
        OpsColumn('الرحلة', flex: 6, minWidth: 132),
        OpsColumn('الرخصة', flex: 5, sortable: true, minWidth: 110),
        OpsColumn('آخر تحديث', flex: 4, minWidth: 88),
        OpsColumn('إجراءات', flex: 6, minWidth: 132),
      ],
      rows: paged.map((driver) {
        final snapshot = DriverOperations.snapshot(driver, workspace);
        final tone = _healthTone(snapshot.health);
        return [
          Checkbox(
            value: selectedIds.contains(driver.id),
            onChanged: (_) => cubit.toggleSelection(driver.id),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          _DriverIdentityCell(
            driver: driver,
            selected: driver.id == selectedId,
            ringColor: context.status(tone).ink,
          ),
          FleetStatusReasonCell(
            label: snapshot.status.label,
            tone: tone,
            // Only when something is wrong: "جاهز للتشغيل" under a green chip
            // that already says "متاح" is a second copy of the same word.
            note: snapshot.requiresAttention ? snapshot.primaryReason : null,
            tooltip: snapshot.attentionReasons.isEmpty
                ? 'جاهز للتشغيل'
                : snapshot.attentionReasons.join('\n'),
          ),
          FleetPairingCell(
            icon: DashboardIcons.vehicle,
            value: _vehicleName(driver.currentVehicleId),
            emptyLabel: 'بدون مركبة',
          ),
          FleetTripCell(
            underway: workspace.underwayDutyOfDriver(driver),
            next: workspace.nextDutyOfDriver(driver),
          ),
          FleetExpiryCell(date: driver.licenseExpiry),
          FleetLastUpdatedCell(updatedAt: driver.updatedAt),
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
  final Color ringColor;

  const _DriverIdentityCell({
    required this.driver,
    required this.selected,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = [
      if (driver.employeeCode.isNotEmpty) driver.employeeCode,
      if (driver.phone.isNotEmpty) driver.phone,
    ].join(' • ');

    return Row(
      children: [
        FleetAvatar(
          label: driver.imageLabel,
          profileImageUrl: driver.profileImageUrl,
          ringColor: ringColor,
          size: 34,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                driver.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : DashboardColors.ink(context),
                ),
              ),
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
              ],
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
        FleetRowActionButton(
          tooltip: 'عرض جاهزية السائق',
          icon: Icons.visibility_outlined,
          onPressed: onView,
        ),
        FleetRowActionButton(
          tooltip: 'تعديل بيانات السائق',
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        PopupMenuButton<String>(
          tooltip: 'المزيد من الإجراءات',
          icon: Icon(
            Icons.more_vert_rounded,
            size: 18,
            color: DashboardColors.mutedInk(context),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 220),
          iconSize: 18,
          splashRadius: 18,
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
                child: _RowMenuItem(
                  icon: Icons.pause_circle_outline_rounded,
                  label: 'إيقاف السائق',
                ),
              ),
            if (driver.status == FleetDriverStatus.suspended)
              const PopupMenuItem(
                value: 'activate',
                child: _RowMenuItem(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'تفعيل السائق',
                ),
              ),
            PopupMenuItem(
              value: 'archive',
              child: _RowMenuItem(
                icon: Icons.archive_outlined,
                label: 'أرشفة السائق',
                color: Theme.of(ctx).colorScheme.error,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: _RowMenuItem(
                icon: Icons.delete_outline_rounded,
                label: 'حذف من قاعدة البيانات',
                color: Theme.of(ctx).colorScheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RowMenuItem extends StatelessWidget {
  const _RowMenuItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }
}
