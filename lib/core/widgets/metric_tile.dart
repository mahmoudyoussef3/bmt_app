import 'package:flutter/material.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget? icon;
  final String? trend;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final rowChildren = <Widget>[];
    if (icon != null) rowChildren.add(icon!);
    if (trend != null) {
      rowChildren.add(
        Text(
          trend!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: rowChildren,
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
