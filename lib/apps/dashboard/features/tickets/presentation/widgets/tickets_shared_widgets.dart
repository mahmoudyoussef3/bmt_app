import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../../domain/entities/complaint.dart';

class StatusBadge extends StatelessWidget {
  final ComplaintStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ComplaintStatus.newlyCreated => Colors.blue,
      ComplaintStatus.inProgress => Colors.orange,
      ComplaintStatus.waitingForClient => Colors.purple,
      ComplaintStatus.resolved => Colors.green,
      ComplaintStatus.closed => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  final ComplaintPriority priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      ComplaintPriority.low => Colors.grey,
      ComplaintPriority.medium => Colors.blue,
      ComplaintPriority.high => Colors.orange,
      ComplaintPriority.critical => Colors.red.shade900,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        priority.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class DetailField extends StatelessWidget {
  final String label;
  final String value;
  const DetailField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label: ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final bool isAlert;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Container(
        decoration: isAlert
            ? BoxDecoration(
                border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1.5),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              radius: 24,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: AppSpacing.medium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isAlert ? Colors.red : scheme.onSurface,
                      ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DropdownFilter<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelMapper;
  final ValueChanged<T?> onChanged;

  const DropdownFilter({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelMapper,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        DropdownButton<T>(
          value: value,
          hint: Text('الكل', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text('الكل', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelMapper(item)),
              ),
            )
          ],
          onChanged: onChanged,
          underline: const SizedBox(),
        ),
      ],
    );
  }
}
