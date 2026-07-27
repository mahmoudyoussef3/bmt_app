import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class FleetVehiclesTable extends StatelessWidget {
  final List<FleetVehicle> vehicles;
  final FleetWorkspace workspace;
  final ValueChanged<FleetVehicle> onView;
  final ValueChanged<FleetVehicle> onEdit;
  final Set<String> selectedIds;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

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
  });

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

    return OpsDataTable(
      columns: const [
        OpsColumn('تحديد', flex: 1, minWidth: 64),
        OpsColumn('المركبة', flex: 5, minWidth: 260),
        OpsColumn('السائق', flex: 3, minWidth: 150),
        OpsColumn('الحالة التشغيلية', flex: 3, minWidth: 150),
        OpsColumn('حالة السجل', flex: 2, minWidth: 118),
        OpsColumn('الوثائق', flex: 4, minWidth: 220),
        OpsColumn('إجراءات', flex: 2, minWidth: 112),
      ],
      total: vehicles.length,
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      rows: paged.map((vehicle) {
        final driverName = _driverName(vehicle.currentDriverId);
        return [
          Checkbox(
            value: selectedIds.contains(vehicle.id),
            onChanged: (_) => cubit.toggleSelection(vehicle.id),
          ),
          _VehicleIdentityCell(vehicle: vehicle),
          Text(
            driverName.isEmpty ? 'بدون سائق' : driverName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          FleetOperationalChip(
            status: workspace.operationalStatusOf(vehicle),
            duty: workspace.currentDutyOf(vehicle),
          ),
          StatusChip(label: vehicle.status.label),
          _VehicleDocumentsCell(vehicle: vehicle),
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
    return Row(
      children: [
        FleetVehicleThumb(
          label: vehicle.imageLabel,
          imageUrl: vehicle.imageUrl,
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.vehicleNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '${vehicle.plateNumber} • ${vehicle.brand} ${vehicle.model} ${vehicle.modelYear} • ${vehicle.capacity} مقعد',
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

class _VehicleDocumentsCell extends StatelessWidget {
  const _VehicleDocumentsCell({required this.vehicle});

  final FleetVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final docs = [
      _VehicleDocDate(label: 'رخصة', value: vehicle.licenseExpiry),
      _VehicleDocDate(label: 'تأمين', value: vehicle.insuranceExpiry),
      _VehicleDocDate(label: 'فحص', value: vehicle.inspectionExpiry),
    ].where((doc) => doc.value.trim().isNotEmpty).toList();

    if (docs.isEmpty) {
      return Text(
        'بيانات الوثائق غير مكتملة',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: docs.map((doc) => _VehicleDocChip(doc: doc)).toList(),
    );
  }
}

class _VehicleDocDate {
  const _VehicleDocDate({required this.label, required this.value});

  final String label;
  final String value;
}

class _VehicleDocChip extends StatelessWidget {
  const _VehicleDocChip({required this.doc});

  final _VehicleDocDate doc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(95),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(65)),
      ),
      child: Text(
        '${doc.label} ${doc.value}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
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
        IconButton(
          tooltip: 'عرض المركبة',
          onPressed: onView,
          icon: const Icon(Icons.visibility_outlined),
        ),
        IconButton(
          tooltip: 'تعديل المركبة',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        PopupMenuButton<String>(
          tooltip: 'المزيد من الإجراءات',
          icon: const Icon(Icons.more_vert_rounded),
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
                child: Row(
                  children: [
                    Icon(Icons.pause_circle_outline_rounded),
                    SizedBox(width: AppSpacing.small),
                    Text('إيقاف المركبة'),
                  ],
                ),
              ),
            if (vehicle.status == FleetVehicleStatus.suspended)
              const PopupMenuItem(
                value: 'activate',
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded),
                    SizedBox(width: AppSpacing.small),
                    Text('تفعيل المركبة'),
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
                    'أرشفة المركبة',
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
    if (confirmed == true) {
      cubit.deleteVehicle(vehicle.id);
    }
  }
}
