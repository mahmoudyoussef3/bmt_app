import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_table_shell.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
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

  Color _healthColor(BuildContext context, DriverHealthLevel health) {
    final scheme = Theme.of(context).colorScheme;
    return switch (health) {
      DriverHealthLevel.healthy => scheme.primary,
      DriverHealthLevel.warning => scheme.tertiary,
      DriverHealthLevel.critical => scheme.error,
    };
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
      total: drivers.length,
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      rows: paged.map((driver) {
        final vehicle = _vehicleName(driver.currentVehicleId);
        final snapshot = DriverOperations.snapshot(driver, workspace);
        final healthColor = _healthColor(context, snapshot.health);
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
              color: healthColor.withAlpha(24),
              textColor: healthColor,
            ),
          ),
          StatusChip(label: snapshot.status.label),
          Text(vehicle.isEmpty ? 'بدون مركبة' : vehicle),
          Text(
            driver.licenseExpiry,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Wrap(
            spacing: AppSpacing.xSmall,
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
              IconButton(
                tooltip: 'إيقاف السائق',
                onPressed: driver.status == FleetDriverStatus.active
                    ? () => cubit.updateDriverStatus(
                        driver.id,
                        FleetDriverStatus.suspended,
                      )
                    : null,
                icon: const Icon(Icons.pause_circle_outline_rounded),
              ),
              IconButton(
                tooltip: 'تفعيل السائق',
                onPressed: driver.status == FleetDriverStatus.suspended
                    ? () => cubit.updateDriverStatus(
                        driver.id,
                        FleetDriverStatus.active,
                      )
                    : null,
                icon: const Icon(Icons.play_circle_outline_rounded),
              ),
              IconButton(
                tooltip: 'أرشفة السائق',
                onPressed: () => cubit.updateDriverStatus(
                  driver.id,
                  FleetDriverStatus.archived,
                ),
                icon: const Icon(Icons.archive_outlined),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }
}
