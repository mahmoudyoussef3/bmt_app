import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_format.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicles_toolbar.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// المركبات, as a table — [FleetDriversTable]'s twin one tab over.
///
/// Deliberately the same eight columns in the same order and the same widths
/// as السائقون: identity, status, pairing, trip, validity, freshness, actions.
/// Switching tabs should move the data under the operator's eye, not move the
/// operator's eye. See that class for why the column budget adds up to 946px.
class FleetVehiclesTable extends StatelessWidget {
  final List<FleetVehicle> vehicles;
  final FleetWorkspace workspace;
  final ValueChanged<FleetVehicle> onView;
  final ValueChanged<FleetVehicle> onEdit;
  final Set<String> selectedIds;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  /// The ordering in force, so a sorted column can mark itself. Lives in the
  /// screen rather than here because the toolbar's pinned sort control and
  /// these headers must drive one value.
  final FleetVehicleSort sort;
  final bool sortAscending;
  final ValueChanged<FleetVehicleSort> onSort;

  const FleetVehiclesTable({
    super.key,
    required this.vehicles,
    required this.workspace,
    required this.onView,
    required this.onEdit,
    required this.selectedIds,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.sort,
    required this.sortAscending,
    required this.onSort,
  });

  /// Column index → sort key. Indices absent from this map are not sortable.
  static const _sortColumns = <int, FleetVehicleSort>{
    1: FleetVehicleSort.code,
    3: FleetVehicleSort.status,
  };

  String _driverName(String driverId) {
    if (driverId.isEmpty) return '';
    final match = workspace.drivers.where((d) => d.id == driverId);
    if (match.isEmpty) return '';
    return match.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetVehiclesCubit>();
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, vehicles.length);
    final paged = start >= vehicles.length
        ? <FleetVehicle>[]
        : vehicles.sublist(start, end);
    final suspendedTint = context.status(AppStatusTone.error).tint;

    return OpsDataTable(
      sortColumnIndex: _sortColumns.entries
          .where((e) => e.value == sort)
          .map((e) => e.key)
          .firstOrNull,
      sortDirection: sortAscending ? OpsSort.asc : OpsSort.desc,
      onSort: (index) {
        final key = _sortColumns[index];
        if (key != null) onSort(key);
      },
      columns: const [
        OpsColumn('تحديد', flex: 2, minWidth: 44),
        OpsColumn('المركبة', flex: 9, minWidth: 198, sortable: true),
        OpsColumn('السائق', flex: 5, minWidth: 110),
        OpsColumn('الحالة', flex: 6, minWidth: 132, sortable: true),
        OpsColumn('الرحلة', flex: 6, minWidth: 132),
        OpsColumn('الوثائق', flex: 5, minWidth: 110),
        OpsColumn('آخر تحديث', flex: 4, minWidth: 88),
        OpsColumn('إجراءات', flex: 6, minWidth: 132),
      ],
      total: vehicles.length,
      totalLabel: 'الإجمالي ${FleetFormat.count(vehicles.length)} مركبة',
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      onRowTap: [for (final vehicle in paged) () => onView(vehicle)],
      rowTints: [
        for (final vehicle in paged)
          vehicle.status == FleetVehicleStatus.suspended ? suspendedTint : null,
      ],
      emptyState: const DashboardEmptyState(
        icon: DashboardIcons.vehicle,
        title: 'لا توجد مركبات مطابقة',
        message:
            'لا تطابق أي مركبة البحث أو الفلاتر الحالية. وسّع الفلاتر، أو أضف '
            'مركبة جديدة إلى الأسطول.',
      ),
      rows: paged.map((vehicle) {
        final operational = workspace.operationalStatusOf(vehicle);
        final duty = workspace.currentDutyOf(vehicle);
        return [
          Checkbox(
            value: selectedIds.contains(vehicle.id),
            onChanged: (_) => cubit.toggleSelection(vehicle.id),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          _VehicleIdentityCell(vehicle: vehicle),
          FleetPairingCell(
            icon: DashboardIcons.captains,
            value: _driverName(vehicle.currentDriverId),
            emptyLabel: 'غير مخصص',
          ),
          // The live state and the record state, in one column.
          //
          // The record line shows *only* when the two disagree — which happens
          // exactly when a trip is under way, since an in-flight trip outranks
          // the record (see `resolveOperationalStatus`). In every other case
          // the chip already is the record status in other words, and printing
          // both gave rows that read "في الصيانة / السجل: صيانة".
          FleetStatusReasonCell(
            label: operational.label,
            tone: fleetOperationalTone(operational),
            note:
                operational == FleetOperationalStatus.onTrip &&
                    vehicle.status != FleetVehicleStatus.active
                ? 'السجل: ${vehicle.status.label}'
                : null,
            tooltip: [
              'الحالة التشغيلية: ${operational.label}',
              'حالة السجل: ${vehicle.status.label}',
              if (duty != null)
                'رحلة ${duty.tripCode}'
                    '${duty.routeName.isEmpty ? '' : ' • ${duty.routeName}'}',
            ].join('\n'),
          ),
          FleetTripCell(
            underway: workspace.underwayDutyOf(vehicle),
            next: workspace.nextDutyOf(vehicle),
          ),
          FleetDocumentsHealthCell(
            documents: [
              FleetDatedDocument(label: 'رخصة', date: vehicle.licenseExpiry),
              FleetDatedDocument(label: 'تأمين', date: vehicle.insuranceExpiry),
              FleetDatedDocument(label: 'فحص', date: vehicle.inspectionExpiry),
            ],
          ),
          FleetLastUpdatedCell(updatedAt: vehicle.updatedAt),
          _VehicleRowActions(
            vehicle: vehicle,
            onView: () => onView(vehicle),
            onEdit: () => onEdit(vehicle),
            cubit: cubit,
          ),
        ];
      }).toList(),
    );
  }
}

class _VehicleIdentityCell extends StatelessWidget {
  const _VehicleIdentityCell({required this.vehicle});

  final FleetVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final spec = [
      if (vehicle.plateNumber.isNotEmpty) vehicle.plateNumber,
      [
        vehicle.brand,
        vehicle.model,
        if (vehicle.modelYear > 0) '${vehicle.modelYear}',
      ].where((part) => part.trim().isNotEmpty).join(' '),
    ].where((part) => part.trim().isNotEmpty).join(' • ');

    return Tooltip(
      message:
          '${vehicle.vehicleNumber}'
          '${spec.isEmpty ? '' : '\n$spec'}'
          '\n${FleetFormat.count(vehicle.capacity)} مقعد',
      child: Row(
        children: [
          FleetVehicleThumb(
            label: vehicle.imageLabel,
            imageUrl: vehicle.imageUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        vehicle.vehicleNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.ink(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Seats stay on the identity line rather than in a column
                    // of their own: it is what a dispatcher matches a booking
                    // against, and it is four characters wide.
                    Text(
                      '${FleetFormat.count(vehicle.capacity)} مقعد',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (spec.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    spec,
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
      ),
    );
  }
}

class _VehicleRowActions extends StatelessWidget {
  const _VehicleRowActions({
    required this.vehicle,
    required this.onView,
    required this.onEdit,
    required this.cubit,
  });

  final FleetVehicle vehicle;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final FleetVehiclesCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FleetRowActionButton(
          tooltip: 'عرض المركبة',
          icon: Icons.visibility_outlined,
          onPressed: onView,
        ),
        FleetRowActionButton(
          tooltip: 'تعديل المركبة',
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
              cubit.updateVehicleStatus(
                vehicle.id,
                FleetVehicleStatus.suspended,
              );
            } else if (value == 'activate') {
              cubit.updateVehicleStatus(vehicle.id, FleetVehicleStatus.active);
            } else if (value == 'archive') {
              cubit.updateVehicleStatus(
                vehicle.id,
                FleetVehicleStatus.archived,
              );
            } else if (value == 'delete') {
              _deleteWithConfirmation(context);
            }
          },
          itemBuilder: (ctx) => [
            if (vehicle.status == FleetVehicleStatus.active)
              const PopupMenuItem(
                value: 'suspend',
                child: _RowMenuItem(
                  icon: Icons.pause_circle_outline_rounded,
                  label: 'إيقاف المركبة',
                ),
              ),
            if (vehicle.status == FleetVehicleStatus.suspended)
              const PopupMenuItem(
                value: 'activate',
                child: _RowMenuItem(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'تفعيل المركبة',
                ),
              ),
            PopupMenuItem(
              value: 'archive',
              child: _RowMenuItem(
                icon: Icons.archive_outlined,
                label: 'أرشفة المركبة',
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

  Future<void> _deleteWithConfirmation(BuildContext context) async {
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
    if (confirmed != true) return;
    final error = await cubit.deleteVehicle(vehicle.id);
    if (!context.mounted) return;
    if (error == null) {
      AppSnackbar.success(context, 'تم حذف المركبة "${vehicle.vehicleNumber}"');
    } else {
      AppSnackbar.error(context, error);
    }
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
