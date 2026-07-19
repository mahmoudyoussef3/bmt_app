import 'package:flutter/material.dart';

/// The four-segment progress indicator for the daily booking wizard.
class DailyBookingProgress extends StatelessWidget {
  const DailyBookingProgress({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(4, (index) {
        final active = index + 1 <= step;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsetsDirectional.only(end: index == 3 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? scheme.primary : scheme.surface.withAlpha(40),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}
