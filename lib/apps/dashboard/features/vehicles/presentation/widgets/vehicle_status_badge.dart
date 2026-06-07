import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/vehicle.dart';

class VehicleStatusBadge extends StatelessWidget {
  final VehicleStatus status;

  const VehicleStatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      VehicleStatus.active => scheme.primaryContainer,
      VehicleStatus.outOfService => scheme.errorContainer,
      VehicleStatus.maintenance => scheme.tertiaryContainer,
      VehicleStatus.pendingAssignment => scheme.secondaryContainer,
    };
    final textColor = switch (status) {
      VehicleStatus.active => scheme.onPrimaryContainer,
      VehicleStatus.outOfService => scheme.onErrorContainer,
      VehicleStatus.maintenance => scheme.onTertiaryContainer,
      VehicleStatus.pendingAssignment => scheme.onSecondaryContainer,
    };

    return StatusChip(label: status.label, color: color, textColor: textColor);
  }
}
