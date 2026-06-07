import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/driver.dart';

class DriverStatusBadge extends StatelessWidget {
  final DriverStatus status;

  const DriverStatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    return StatusChip(label: status.label);
  }
}
