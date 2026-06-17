import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_table_shell.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetDriversTable extends StatelessWidget {
  final List<FleetDriver> drivers;
  final FleetWorkspace workspace;
  final ValueChanged<FleetDriver> onView;
  final ValueChanged<FleetDriver> onEdit;
  final Set<String> selectedIds;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const FleetDriversTable({
    super.key,
    required this.drivers,
    required this.workspace,
    required this.onView,
    required this.onEdit,
    required this.selectedIds,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetDriversCubit>();
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, drivers.length);
    final paged = start >= drivers.length
        ? <FleetDriver>[]
        : drivers.sublist(start, end);

    return FleetTableShell(
      headers: const [
        'تحديد',
        'السائق',
        'الصحة',
        'التوفر',
        'المركبة',
        'الرخصة',
        'إجراءات',
      ],
      columnFlexes: const [1, 3, 2, 2, 2, 2, 2],
      total: drivers.length,
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      rows: paged.map((driver) {
        final vehicle = _vehicleName(driver.currentVehicleId);
        final snapshot = DriverOperations.snapshot(driver, workspace);
        final (healthBg, healthFg) = _healthColors(snapshot.health);
        return [
          Checkbox(
            value: selectedIds.contains(driver.id),
            onChanged: (_) => cubit.toggleSelection(driver.id),
          ),
          Row(
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'عرض جاهزية السائق',
                onPressed: () => onView(driver),
                icon: const Icon(Icons.visibility_outlined),
              ),
              IconButton(
                tooltip: 'تعديل بيانات السائق',
                onPressed: () => onEdit(driver),
                icon: const Icon(Icons.edit_outlined),
              ),
              PopupMenuButton<String>(
                tooltip: 'المزيد من الإجراءات',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'suspend') {
                    cubit.updateDriverStatus(
                      driver.id,
                      FleetDriverStatus.suspended,
                    );
                  } else if (value == 'activate') {
                    cubit.updateDriverStatus(
                      driver.id,
                      FleetDriverStatus.active,
                    );
                  } else if (value == 'archive') {
                    _archiveWithConfirmation(context, driver, cubit);
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
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }
}
