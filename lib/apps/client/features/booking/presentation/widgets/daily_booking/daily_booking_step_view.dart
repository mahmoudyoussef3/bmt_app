import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/daily_booking_data.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/daily_booking/daily_selection_list.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/daily_booking/daily_time_grid.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/daily_booking/daily_vehicles_step.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Renders the active step of the daily booking wizard.
class DailyBookingStepView extends StatelessWidget {
  const DailyBookingStepView({
    super.key,
    required this.step,
    required this.data,
    required this.pickup,
    required this.destination,
    required this.time,
    required this.controller,
    required this.onSelectPickup,
    required this.onSelectDestination,
    required this.onSelectTime,
    required this.onBook,
  });

  final int step;
  final DailyBookingData data;
  final String pickup;
  final String destination;
  final String time;
  final ScrollController controller;
  final ValueChanged<String> onSelectPickup;
  final ValueChanged<String> onSelectDestination;
  final ValueChanged<String> onSelectTime;
  final ValueChanged<DailyBookingVehicle> onBook;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (step) {
      case 1:
        return DailySelectionList(
          title: context.l10n.booking_selectPickupPoint,
          items: data.pickupPoints,
          activeColor: scheme.primary,
          onSelect: onSelectPickup,
        );
      case 2:
        return DailySelectionList(
          title: context.l10n.booking_selectDestination,
          items: data.destinations,
          activeColor: scheme.secondary,
          onSelect: onSelectDestination,
        );
      case 3:
        return DailyTimeGrid(times: data.arrivalTimes, onSelect: onSelectTime);
      default:
        return DailyVehiclesStep(
          data: data,
          pickup: pickup,
          destination: destination,
          time: time,
          controller: controller,
          onBook: onBook,
        );
    }
  }
}
