import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/filter_chip_group.dart';

/// A [FilterChipGroup] variant for a nullable string dimension with an
/// "Any" option prepended (e.g. departure, destination, vehicle type).
class NullableFilterChipGroup extends StatelessWidget {
  const NullableFilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.anyLabel = 'Any',
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String anyLabel;

  @override
  Widget build(BuildContext context) {
    return FilterChipGroup<String?>(
      label: label,
      options: [null, ...options],
      optionLabel: (value) => value ?? anyLabel,
      selected: selected,
      onSelected: onSelected,
    );
  }
}
