import 'package:flutter/material.dart';

import 'package:bmt_app/core/pricing/package_tier_pricing.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import 'trip_fare_controllers.dart';

/// The ONE fare editor used by both trip creation (the planner's pricing
/// panel) and trip editing (the trip-pricing dialog): a single base ticket
/// fare that auto-derives the four package tiers, each still overridable.
///
/// Package tiers are TOTAL package prices, not per-ride — see
/// [PackageTierPricing].
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
                controllers.syncTiersFromBase();
                onChanged();
              },
            ),
            for (final tier in PackageTierPricing.tiers)
              _FareField(
                width: width,
                label: _tierLabel(tier),
                controller: controllers.tierController(tier),
                helper: _tierHelper(tier, base),
                onChanged: () {
                  controllers.markTiersEdited();
                  onChanged();
                },
              ),
          ],
        );
      },
    );
  }

  static String _tierLabel(PackageTier tier) {
    return switch (tier.key) {
      'five_days' => 'باقة ٥ رحلات',
      'ten_days' => 'باقة ١٠ رحلات',
      'monthly' => 'باقة شهرية (٢٢ رحلة)',
      _ => 'باقة ٣ شهور (٦٦ رحلة)',
    };
  }

  /// Shows the operator what the rider saves versus paying per ride — the
  /// same comparison the Client app's package card renders.
  static String _tierHelper(PackageTier tier, double base) {
    if (base <= 0) return '${tier.rides} رحلات';
    final regular = tier.regularTotalFor(base);
    return '${tier.rides} رحلات • بدون باقة: ${regular.toStringAsFixed(0)} ج.م';
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
