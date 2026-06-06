import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class BookingSummaryCard extends StatelessWidget {
  final String pickup;
  final String destination;
  final String time;

  const BookingSummaryCard({
    super.key,
    required this.pickup,
    required this.destination,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(14),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(label: 'From', value: pickup),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCell(label: 'To', value: destination),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCell(label: 'Time', value: time),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(
          value.isEmpty ? '-' : value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
