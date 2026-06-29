import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_route.dart';

class RouteStatusBadge extends StatelessWidget {
  final OperationRouteStatus status;

  const RouteStatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    return StatusChip(label: status.label);
  }
}
