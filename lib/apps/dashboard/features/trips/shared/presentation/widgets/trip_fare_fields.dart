import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/trip_pricable_package.dart';
import 'trip_fare_controllers.dart';

/// The ONE fare editor used by both trip creation (the planner's pricing
/// panel) and trip editing (the trip-pricing dialog): a single base ticket
/// fare, plus one field per the office's own active packages, each still
/// overridable.
///
/// Package fields are TOTAL package prices, not per-ride.
class TripFareFields extends StatelessWidget {
  const TripFareFields({
    super.key,
    required this.controllers,
    required this.onChanged,
  });

  final TripFareControllers controllers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final base = controllers.baseFare;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 560
            ? (constraints.maxWidth - AppSpacing.small) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            _FareField(
              width: width,
              label: 'سعر التذكرة (رحلة واحدة)',
              controller: controllers.oneTime,
              onChanged: () {
                controllers.syncPricesFromBase();
                onChanged();
              },
            ),
            for (final package in controllers.packages)
              _FareField(
                width: width,
                label: package.name,
                controller: controllers.controllerFor(package),
                helper: _packageHelper(package, base),
                onChanged: () {
                  controllers.markPricesEdited();
                  onChanged();
                },
              ),
          ],
        );
      },
    );
  }

  /// Shows the operator what the rider saves versus paying per ride — the
  /// same comparison the Client app's package card renders.
  static String _packageHelper(TripPricablePackage package, double base) {
    if (base <= 0) return '${package.rideCount} رحلات';
    final regular = base * package.rideCount;
    return '${package.rideCount} رحلات • بدون باقة: ${regular.toStringAsFixed(0)} ج.م';
  }
}

class _FareField extends StatelessWidget {
  const _FareField({
    required this.width,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.helper,
  });

  final double width;
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          suffixText: 'ج.م',
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
