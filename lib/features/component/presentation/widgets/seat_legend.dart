import 'package:flutter/material.dart';

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  Widget _item(
    BuildContext context,
    String label,
    Color color, {
    bool muted = false,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: muted ? Theme.of(context).cardColor.withAlpha(20) : color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(80),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _item(context, 'Available', Theme.of(context).cardColor),
        _item(context, 'Selected', scheme.primary),
        _item(context, 'Reserved', Colors.grey, muted: true),
      ],
    );
  }
}
