import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_trip.dart';

class TripStatusBadge extends StatelessWidget {
  final OperationTripStatus status;

  const TripStatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    return StatusChip(label: status.label);
  }
}
