import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A labeled range slider for filter sheets (price, duration, seats, ...).
/// Shows the currently selected range as formatted text above the track so
/// the active selection is legible without opening a separate input.
class FilterRangeSlider extends StatelessWidget {
  const FilterRangeSlider({
    super.key,
    required this.label,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.labelFormatter,
    this.divisions,
  });

  final String label;
  final RangeValues values;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<RangeValues> onChanged;
  final String Function(double value) labelFormatter;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ClientTypography.labelLarge(context)),
            Text(
              '${labelFormatter(values.start)} – ${labelFormatter(values.end)}',
              style: ClientTypography.labelLarge(
                context,
              ).copyWith(color: primary, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: primary,
            inactiveTrackColor: ClientColors.borderFor(context),
            thumbColor: primary,
            overlayColor: primary.withAlpha(30),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
