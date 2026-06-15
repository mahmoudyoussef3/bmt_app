import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        'الصورة',
        'الاسم',
        'رقم الهاتف',
        'الرقم القومي',
        'رقم الرخصة',
        'انتهاء الرخصة',
        'الحالة',
        'المركبة الحالية',
        'إجراءات',
      ],
      total: drivers.length,
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      rows: paged.map((driver) {
        final vehicle = _vehicleName(driver.currentVehicleId);
        return [
          Checkbox(
            value: selectedIds.contains(driver.id),
            onChanged: (_) => cubit.toggleSelection(driver.id),
          ),
          FleetAvatar(
            label: driver.imageLabel,
            profileImageUrl: driver.profileImageUrl,
          ),
          Text(
            driver.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(driver.phone),
          Text(driver.nationalId),
          Text(driver.licenseNumber),
          Text(driver.licenseExpiry),
          StatusChip(label: driver.status.label),
          Text(vehicle.isEmpty ? 'بدون مركبة' : vehicle),
          Wrap(
            spacing: AppSpacing.xSmall,
            children: [
              TextButton(
                onPressed: () => onView(driver),
                child: const Text('عرض'),
              ),
              TextButton(
                onPressed: () => onEdit(driver),
                child: const Text('تعديل'),
              ),
              TextButton(
                onPressed: driver.status == FleetDriverStatus.active
                    ? () => cubit.updateDriverStatus(
                        driver.id,
                        FleetDriverStatus.suspended,
                      )
                    : null,
                child: const Text('إيقاف'),
              ),
              TextButton(
                onPressed: driver.status == FleetDriverStatus.suspended
                    ? () => cubit.updateDriverStatus(
                        driver.id,
                        FleetDriverStatus.active,
                      )
                    : null,
                child: const Text('تفعيل'),
              ),
              TextButton(
                onPressed: () => cubit.updateDriverStatus(
                  driver.id,
                  FleetDriverStatus.archived,
                ),
                child: const Text('أرشفة'),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }
}
