import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// How a selected segment is drawn, which is how the reader tells one bar's
/// job from another's when two sit on the same toolbar.
enum DashboardSegmentTone {
  /// The bar that changes *what you are looking at* — a section switcher.
  /// Brand fill, white ink: the strongest mark on the toolbar.
  accent,

  /// The bar that changes *how much of it you are looking at* — a period or
  /// scope switcher. The selected segment lifts onto the panel surface with
  /// brand ink, so it reads as chosen without competing with the section bar.
  raised,
}

/// One choice in a [DashboardSegmentedBar].
@immutable
class DashboardSegment<T> {
  final T value;
  final String label;

  /// Optional leading glyph. Keep it off unless the icon adds meaning the
  /// label does not — a row of decorated segments is just noisier.
  final IconData? icon;

  /// A count carried on the segment, already formatted. Rendered as a small
  /// counter so an operator working in another section is not the last to
  /// know that one has work waiting in it.
  final String? badge;

  /// Tooltip. Use it when the label is abbreviated.
  final String? tooltip;

  const DashboardSegment({
    required this.value,
    required this.label,
    this.icon,
    this.badge,
    this.tooltip,
  });
}

/// The console's segmented switcher: one bordered group, one selected segment.
///
/// Material's [SegmentedButton] is what the dashboard reached for before, and
/// it brings M3's own selected-container colour — a pale green against a
/// console whose entire vocabulary is warm paper and brand blue — plus a fixed
/// height and no wrapping, so a seven-preset period switcher either overflowed
/// or had to be put in a horizontal scroller the operator could not see the end
/// of. This is the same control in the console's own colours, and it wraps.
///
/// It is deliberately not a filter chip row: chips are independently
/// selectable and read as "any number of these", while a segmented bar reads as
/// "exactly one of these", which is what a section and a reporting period both
/// are.
class DashboardSegmentedBar<T> extends StatelessWidget {
  final List<DashboardSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;
  final DashboardSegmentTone tone;

  /// Trims the segment padding for a bar that shares a toolbar row with
  /// another one.
  final bool dense;

  const DashboardSegmentedBar({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.tone = DashboardSegmentTone.accent,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          for (final segment in segments)
            _Segment<T>(
              segment: segment,
              selected: segment.value == selected,
              tone: tone,
              dense: dense,
              onTap: () => onSelected(segment.value),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.tone,
    required this.dense,
    required this.onTap,
  });

  final DashboardSegment<T> segment;
  final bool selected;
  final DashboardSegmentTone tone;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(7);

    final (fill, ink) = switch ((selected, tone)) {
      (false, _) => (Colors.transparent, DashboardColors.mutedInk(context)),
      (true, DashboardSegmentTone.accent) => (
        DashboardColors.accentFill(context),
        DashboardColors.onHero(context),
      ),
      // A *tint* of the brand, not the panel surface. Filling with `panel`
      // lifts the segment in light mode and sinks it in dark, where the group's
      // own `nested` background is the lighter of the two — the selected
      // period was very nearly invisible on the dark console.
      (true, DashboardSegmentTone.raised) => (
        DashboardColors.kpiTint(context, DashboardColors.accentInk(context)),
        DashboardColors.accentInk(context),
      ),
    };

    final tile = Material(
      color: fill,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 13,
            vertical: dense ? 6 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(segment.icon, size: 16, color: ink),
                const SizedBox(width: 6),
              ],
              Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: ink,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (segment.badge != null) ...[
                const SizedBox(width: 6),
                _Badge(
                  text: segment.badge!,
                  onAccent: selected && tone == DashboardSegmentTone.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final tooltip = segment.tooltip;
    return tooltip == null ? tile : Tooltip(message: tooltip, child: tile);
  }
}

/// The count on a segment. Error-toned, because the only thing worth counting
/// on a switcher is work that is waiting.
class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.onAccent});

  final String text;

  /// True when it sits on a brand-filled segment, where the error tint would
  /// muddy rather than mark.
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = onAccent ? DashboardColors.onHero(context) : scheme.error;
    final ink = onAccent ? DashboardColors.accentFill(context) : scheme.onError;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
      ),
    );
  }
}

/// A control that sits *beside* a [DashboardSegmentedBar] and shares its
/// height and shape — the "everything the presets do not cover" escape hatch,
/// such as a custom date range.
///
/// It is a separate control rather than another segment because it does not
/// pick a value: it asks a question first, and a segment that opens a dialog
/// is a segment the operator cannot predict.
class DashboardSegmentedAction extends StatelessWidget {
  const DashboardSegmentedAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  /// True when the value this control produced is the one currently in force.
  final bool active;

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final ink = active
        ? DashboardColors.accentInk(context)
        : DashboardColors.mutedInk(context);

    final button = Material(
      color: active
          ? DashboardColors.kpiTint(context, DashboardColors.accentInk(context))
          : DashboardColors.nested(context),
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: active
                  ? DashboardColors.accentInk(context).withAlpha(90)
                  : DashboardColors.border(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: ink),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: ink,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final message = tooltip;
    return message == null ? button : Tooltip(message: message, child: button);
  }
}
