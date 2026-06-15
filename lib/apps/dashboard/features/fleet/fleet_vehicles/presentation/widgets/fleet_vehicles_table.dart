import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_table_shell.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

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

    return FleetTableShell(
      headers: const [
        'تحديد',
        'الصورة',
        'رقم المركبة',
        'رقم اللوحة',
        'الموديل',
        'السنة',
        'عدد المقاعد',
        'السائق الحالي',
        'الحالة',
        'الرخصة',
        'التأمين',
        'الفحص',
        'إجراءات',
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
          FleetVehicleThumb(
            label: vehicle.imageLabel,
            imageUrl: vehicle.imageUrl,
          ),
          Text(
            vehicle.vehicleNumber,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(vehicle.plateNumber),
          Text(vehicle.model),
          Text('${vehicle.modelYear}'),
          Text('${vehicle.capacity}'),
          Text(driverName.isEmpty ? 'بدون سائق' : driverName),
          StatusChip(label: vehicle.status.label),
          Text(vehicle.licenseExpiry),
          Text(vehicle.insuranceExpiry),
          Text(vehicle.inspectionExpiry),
          Wrap(
            spacing: AppSpacing.xSmall,
            children: [
              TextButton(
                onPressed: () => onView(vehicle),
                child: const Text('عرض'),
              ),
              TextButton(
                onPressed: () => onEdit(vehicle),
                child: const Text('تعديل'),
              ),
              TextButton(
                onPressed: vehicle.status == FleetVehicleStatus.active
                    ? () => cubit.updateVehicleStatus(
                        vehicle.id,
                        FleetVehicleStatus.suspended,
                      )
                    : null,
                child: const Text('إيقاف'),
              ),
              TextButton(
                onPressed: vehicle.status == FleetVehicleStatus.suspended
                    ? () => cubit.updateVehicleStatus(
                        vehicle.id,
                        FleetVehicleStatus.active,
                      )
                    : null,
                child: const Text('تفعيل'),
              ),
              TextButton(
                onPressed: () => cubit.updateVehicleStatus(
                  vehicle.id,
                  FleetVehicleStatus.archived,
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
