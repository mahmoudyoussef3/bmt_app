import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class TimeSelectionChip extends StatelessWidget {
  final String time;
  final bool active;
  final VoidCallback onTap;

  const TimeSelectionChip({
    super.key,
    required this.time,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      radius: 12,
      border: active
          ? Border.all(color: cs.primary, width: 2)
          : Border.all(color: cs.outline.withAlpha(80)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: cs.onSurface),
            const SizedBox(width: 8),
            Text(
              time,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
