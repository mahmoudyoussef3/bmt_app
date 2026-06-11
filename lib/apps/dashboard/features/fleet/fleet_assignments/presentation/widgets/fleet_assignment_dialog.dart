import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_assignment.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_driver.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_assignments/presentation/cubit/fleet_assignments_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';

class FleetAssignmentDialog extends StatefulWidget {
  final FleetAssignment? assignment;
  final List<FleetDriver> drivers;
  final List<FleetVehicle> vehicles;

  const FleetAssignmentDialog({
    super.key,
    this.assignment,
    required this.drivers,
    required this.vehicles,
  });

  @override
  State<FleetAssignmentDialog> createState() => _FleetAssignmentDialogState();
}

class _FleetAssignmentDialogState extends State<FleetAssignmentDialog> {
  String driverId = '';
  String vehicleId = '';
  String error = '';

  @override
  void initState() {
    super.initState();
    driverId = widget.drivers.isEmpty ? '' : widget.drivers.first.id;
    vehicleId = widget.vehicles.isEmpty ? '' : widget.vehicles.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final reassign = widget.assignment != null;
    return AlertDialog(
      title: Text(reassign ? 'تغيير المركبة' : 'تعيين سائق لمركبة'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!reassign)
              DropdownButtonFormField<String>(
                value: driverId.isEmpty ? null : driverId,
                decoration: const InputDecoration(
                  labelText: 'السائق',
                  border: OutlineInputBorder(),
                ),
                items: widget.drivers
                    .map(
                      (driver) => DropdownMenuItem(
                        value: driver.id,
                        child: Text(driver.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => driverId = value ?? ''),
              ),
            if (!reassign) const SizedBox(height: AppSpacing.small),
            DropdownButtonFormField<String>(
              value: vehicleId.isEmpty ? null : vehicleId,
              decoration: const InputDecoration(
                labelText: 'المركبة',
                border: OutlineInputBorder(),
              ),
              items: widget.vehicles
                  .map(
                    (vehicle) => DropdownMenuItem(
                      value: vehicle.id,
                      child: Text(
                        '${vehicle.vehicleNumber} - ${vehicle.plateNumber}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => vehicleId = value ?? ''),
            ),
            if (widget.vehicles.isEmpty || (!reassign && widget.drivers.isEmpty)) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                'لا توجد بيانات متاحة غير معينة حالياً',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (error.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }

  Future<void> _save() async {
    if (vehicleId.isEmpty || (widget.assignment == null && driverId.isEmpty)) {
      setState(() => error = 'اختر السائق والمركبة أولاً');
      return;
    }
    final cubit = context.read<FleetAssignmentsCubit>();
    final result = widget.assignment == null
        ? await cubit.assign(driverId, vehicleId)
        : await cubit.reassign(widget.assignment!.id, vehicleId);

    if (result != null) {
      setState(() => error = result);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }
}
