import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/fleet_assignments/presentation/cubit/fleet_assignments_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetAssignmentDialog extends StatefulWidget {
  final FleetAssignment? assignment;
  final FleetWorkspace workspace;
  final List<FleetDriver> drivers;
  final List<FleetVehicle> vehicles;

  const FleetAssignmentDialog({
    super.key,
    this.assignment,
    required this.workspace,
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
    driverId =
        widget.assignment?.driverId ??
        (widget.drivers.isEmpty ? '' : widget.drivers.first.id);
    vehicleId = widget.vehicles.isEmpty ? '' : widget.vehicles.first.id;
  }

  FleetDriver? get _selectedDriver {
    final allDrivers = widget.assignment == null
        ? widget.drivers
        : widget.workspace.drivers;
    for (final driver in allDrivers) {
      if (driver.id == driverId) return driver;
    }
    return null;
  }

  FleetVehicle? get _selectedVehicle {
    for (final vehicle in widget.vehicles) {
      if (vehicle.id == vehicleId) return vehicle;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final reassign = widget.assignment != null;
    return AlertDialog(
      title: Text(reassign ? 'تغيير المركبة' : 'تعيين سائق لمركبة'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!reassign)
              DropdownButtonFormField<String>(
                initialValue: driverId.isEmpty ? null : driverId,
                decoration: const InputDecoration(
                  labelText: 'السائق',
                  border: OutlineInputBorder(),
                ),
                items: widget.drivers.map((driver) {
                  final snapshot = DriverOperations.snapshot(
                    driver,
                    widget.workspace,
                  );
                  return DropdownMenuItem(
                    value: driver.id,
                    enabled: snapshot.health != DriverHealthLevel.critical,
                    child: _DriverOptionLabel(
                      driver: driver,
                      snapshot: snapshot,
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => driverId = value ?? ''),
              ),
            if (!reassign) const SizedBox(height: AppSpacing.small),
            DropdownButtonFormField<String>(
              initialValue: vehicleId.isEmpty ? null : vehicleId,
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
            const SizedBox(height: AppSpacing.medium),
            _EligibilityPreview(
              driver: _selectedDriver,
              vehicle: _selectedVehicle,
              workspace: widget.workspace,
            ),
            if (widget.vehicles.isEmpty ||
                (!reassign && widget.drivers.isEmpty)) ...[
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
    final driver = _selectedDriver;
    if (driver == null) {
      setState(() => error = 'تعذر تحديد بيانات السائق');
      return;
    }
    final snapshot = DriverOperations.snapshot(driver, widget.workspace);
    if (snapshot.health == DriverHealthLevel.critical) {
      setState(() => error = 'لا يمكن التعيين: ${snapshot.primaryReason}');
      return;
    }
    final vehicle = _selectedVehicle;
    if (vehicle == null || vehicle.status != FleetVehicleStatus.active) {
      setState(() => error = 'المركبة المحددة غير جاهزة للتشغيل');
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

class _DriverOptionLabel extends StatelessWidget {
  const _DriverOptionLabel({required this.driver, required this.snapshot});

  final FleetDriver driver;
  final DriverOperationsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (snapshot.health) {
      DriverHealthLevel.healthy => scheme.primary,
      DriverHealthLevel.warning => scheme.tertiary,
      DriverHealthLevel.critical => scheme.error,
    };

    return Row(
      children: [
        Expanded(
          child: Text(
            driver.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Text(
          snapshot.health.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _EligibilityPreview extends StatelessWidget {
  const _EligibilityPreview({
    required this.driver,
    required this.vehicle,
    required this.workspace,
  });

  final FleetDriver? driver;
  final FleetVehicle? vehicle;
  final FleetWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final driverSnapshot = driver == null
        ? null
        : DriverOperations.snapshot(driver!, workspace);
    final healthColor = switch (driverSnapshot?.health) {
      DriverHealthLevel.healthy => scheme.primary,
      DriverHealthLevel.warning => scheme.tertiary,
      DriverHealthLevel.critical => scheme.error,
      null => scheme.outline,
    };

    final vehicleReady = vehicle?.status == FleetVehicleStatus.active;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فحص أهلية التعيين',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              StatusChip(
                label: driverSnapshot?.canAssign == true
                    ? 'السائق جاهز'
                    : driverSnapshot?.primaryReason ?? 'اختر سائقاً',
                color: healthColor.withAlpha(24),
                textColor: healthColor,
              ),
              StatusChip(
                label: vehicleReady ? 'المركبة جاهزة' : 'المركبة غير جاهزة',
                color: (vehicleReady ? scheme.primary : scheme.error).withAlpha(
                  24,
                ),
                textColor: vehicleReady ? scheme.primary : scheme.error,
              ),
            ],
          ),
          if (driverSnapshot != null &&
              driverSnapshot.attentionReasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            ...driverSnapshot.attentionReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: healthColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(reason)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
