import 'package:flutter/material.dart';

enum SeatStatus { available, reserved, selected }

class SeatWidget extends StatelessWidget {
  final String id;
  final SeatStatus status;
  final VoidCallback? onTap;

  const SeatWidget({
    super.key,
    required this.id,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (status) {
      case SeatStatus.reserved:
        bg = Theme.of(context).colorScheme.onSurface.withOpacity(0.08);
        text = Theme.of(context).textTheme.bodySmall!.color!;
        break;
      case SeatStatus.selected:
        bg = Theme.of(context).colorScheme.primary;
        text = Colors.white;
        break;
      case SeatStatus.available:
        bg = Theme.of(context).cardColor;
        text = Theme.of(context).textTheme.bodyMedium!.color!;
    }

    final child = Container(
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        id,
        style: TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
    );

    if (status == SeatStatus.reserved) {
      return Opacity(opacity: 0.55, child: child);
    }

    return GestureDetector(onTap: onTap, child: child);
  }
}
