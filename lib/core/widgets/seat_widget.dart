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
    final scheme = Theme.of(context).colorScheme;
    final isReserved = status == SeatStatus.reserved;
    final isSelected = status == SeatStatus.selected;

    final backgroundColor = switch (status) {
      SeatStatus.reserved => scheme.surfaceContainerHighest.withAlpha(200),
      SeatStatus.selected => scheme.primary,
      SeatStatus.available => scheme.surface,
    };

    final foregroundColor = switch (status) {
      SeatStatus.reserved => scheme.onSurface.withAlpha(130),
      SeatStatus.selected => scheme.onPrimary,
      SeatStatus.available => scheme.onSurface,
    };

    final borderColor = switch (status) {
      SeatStatus.reserved => scheme.outline.withAlpha(70),
      SeatStatus.selected => scheme.primary,
      SeatStatus.available => scheme.outline.withAlpha(120),
    };

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: scheme.primary.withAlpha(60),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isReserved
                ? Icons.lock_rounded
                : isSelected
                ? Icons.check_rounded
                : Icons.event_seat_rounded,
            size: 16,
            color: foregroundColor,
          ),
          const SizedBox(height: 4),
          Text(
            id,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    if (isReserved) {
      return Opacity(opacity: 0.62, child: child);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}
