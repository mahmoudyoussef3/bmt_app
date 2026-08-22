import 'package:flutter/material.dart';

/// The console's status label: a 6px rounded rect, not a pill.
///
/// Dashboard-scoped twin of the shared `StatusChip` (`core/widgets/status_chip.dart`,
/// which the client and captain apps also use and which keeps its own pill
/// shape) — a full-radius pill in a dense table row reads as a button; a small
/// rect reads as a data label. Same constructor shape as `StatusChip`, so every
/// dashboard call site — almost all of which already resolve [color]/[textColor]
/// via `context.status(tone)` — needed only its import changed, not its data.
class DashboardStatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const DashboardStatusChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = color ?? cs.primary.withAlpha(18);
    final fg = textColor ?? cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(90)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}
