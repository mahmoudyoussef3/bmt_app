import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';

/// A bare-page chip: a hairline outline, a tinted glyph, a muted caption and
/// the figure in ink.
///
/// This is the mark for a fact that is true *right now* — what leaves next,
/// how many buses are rolling, whether the position feed is still live — sitting
/// directly under a page title, above the KPI row. A KPI is a period's total and
/// cannot say any of that.
///
/// Deliberately not [DashboardStatusChip]: that badge tints its whole fill,
/// which is right for a status cell in a dense table and wrong for three chips
/// under a heading, where three filled blocks read as three warnings. Only the
/// glyph takes the tone's colour.
class DashboardPulseChip extends StatelessWidget {
  const DashboardPulseChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tone = AppStatusTone.neutral,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;

  /// What the figure is — «التالية», «جارية الآن». Muted; never the loud half.
  final String label;

  /// The figure itself.
  final String value;

  final AppStatusTone tone;

  /// Opens whatever explains the fact. A chip with nowhere to go stays inert
  /// rather than pretending to be a button.
  final VoidCallback? onTap;

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = DashboardColors.status(context, tone);
    final radius = BorderRadius.circular(8);

    final body = Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardColors.panel(context),
        borderRadius: radius,
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: style.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );

    final chip = onTap == null
        ? body
        : Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(onTap: onTap, borderRadius: radius, child: body),
          );

    final hint = tooltip;
    return hint == null ? chip : Tooltip(message: hint, child: chip);
  }
}
