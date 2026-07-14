import 'package:flutter/material.dart';

/// A horizontal dashed rule. Used where a solid line would read as a hard
/// boundary but the two halves belong to the same object — a ticket's tear
/// line, a route's connector.
class DashedDivider extends StatelessWidget {
  const DashedDivider({
    super.key,
    required this.color,
    this.dashWidth = 4,
    this.gap = 4,
    this.thickness = 1.4,
  });

  final Color color;
  final double dashWidth;
  final double gap;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / (dashWidth + gap))
            .floor()
            .clamp(1, 200);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => SizedBox(
              width: dashWidth,
              height: thickness,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(thickness),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
