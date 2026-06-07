import 'package:flutter/material.dart';

/// Modern seat status legend for the seat selection screen.
class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seat legend',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withAlpha(210),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final wrap = constraints.maxWidth < 520;
            final items = [
              _LegendChip(
                label: 'Available',
                icon: Icons.event_seat_outlined,
                color: scheme.surface,
                borderColor: scheme.outline.withAlpha(140),
                iconColor: scheme.onSurface,
              ),
              _LegendChip(
                label: 'Selected',
                icon: Icons.check_circle_rounded,
                color: scheme.primary,
                borderColor: scheme.primary,
                iconColor: scheme.onPrimary,
                textColor: scheme.onPrimary,
              ),
              _LegendChip(
                label: 'Reserved',
                icon: Icons.lock_rounded,
                color: scheme.surfaceContainerHighest,
                borderColor: scheme.outline.withAlpha(100),
                iconColor: scheme.onSurface.withAlpha(120),
                muted: true,
              ),
       
            ];

            if (wrap) {
              return Wrap(spacing: 8, runSpacing: 8, children: items);
            }
            return Row(
              children: items
                  .map(
                    (chip) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: chip,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    this.textColor,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final Color? textColor;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelColor =
        textColor ??
        (muted ? scheme.onSurface.withAlpha(130) : scheme.onSurface);

    return Opacity(
      opacity: muted ? 0.75 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
