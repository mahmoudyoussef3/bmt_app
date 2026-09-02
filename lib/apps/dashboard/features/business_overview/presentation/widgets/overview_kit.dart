import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

// The shapes this page draws figures with — deliberately the **same shapes
// الرئيسية uses**, because the two screens are read one after the other by the
// same person all day and they used to look like two different products.
//
// Home's rules, adopted here wholesale:
//
// * A figure inside a panel is a **row on the panel's own surface**, not a
//   bordered box. The previous revision of this page nested twenty-three
//   tinted-and-bordered tiles inside already-bordered panels — card-in-card,
//   which the design system calls out as the one thing that always looks
//   wrong, and which is what made the screen tiring to read.
// * Groups of short figures are a **divided strip**, not a grid.
// * A ratio is a **track**: a big figure in a fixed lane, the label, and a
//   rounded `LinearProgressIndicator` over `well`.
// * Colour is spent on **one tinted glyph square** per row and on the figure
//   it belongs to — never on a whole tile's fill, which turns six ordinary
//   queues into six alert boxes shouting at once.
// * Every number carries `FontFeature.tabularFigures()`, so columns of digits
//   line up and a value does not jitter as it updates.

/// A bare-page chip: hairline outline, tinted glyph, muted caption, figure in
/// ink. The same chip Home's pulse strip uses, and deliberately not
/// `DashboardStatusChip` — that badge tints its whole fill, which is right for
/// a status cell in a dense table and wrong for a row of facts under a page
/// title, where filled blocks read as a row of warnings.
class OverviewChip extends StatelessWidget {
  const OverviewChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = DashboardColors.status(context, tone);

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardColors.panel(context),
        borderRadius: BorderRadius.circular(8),
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
  }
}

/// A ratio drawn as a track — the shape Home gives its fleet split and its
/// rating rows, and the right one for the three questions on this page that
/// are genuinely "how much of the whole": collection, retention, fleet use.
///
/// The two notes under the track are the arithmetic behind it, so the bar is
/// never the only evidence: an owner can check it without leaving the panel.
class OverviewTrackRow extends StatelessWidget {
  const OverviewTrackRow({
    super.key,
    required this.label,
    required this.ratio,
    required this.tone,
    this.valueLabel,
    this.trailingNote,
    this.notes = const [],
    this.emptyNote = 'لا توجد بيانات كافية لقياس هذه النسبة.',
    this.onTap,
  });

  final String label;

  /// `0..1`, or null when the ratio could not be measured — which draws
  /// [emptyNote] instead of an empty track. A 0% bar and an unmeasurable one
  /// look identical, and only one of them is a fact.
  final double? ratio;

  final Color tone;

  /// Overrides the printed percentage, for a track whose headline is an amount.
  final String? valueLabel;

  /// Sits at the end of the label line — Home's «من N».
  final String? trailingNote;

  /// The figures behind the ratio, wrapped so neither is ever truncated.
  final List<String> notes;

  final String emptyNote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final measured = ratio;
    final radius = BorderRadius.circular(8);

    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                valueLabel ?? (measured == null ? '—' : _percent(measured)),
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: measured == null
                      ? DashboardColors.faintInk(context)
                      : DashboardColors.ink(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (trailingNote != null)
                      Text(
                        trailingNote!,
                        style: text.labelSmall?.copyWith(
                          color: DashboardColors.faintInk(context),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    if (onTap != null) ...[
                      const SizedBox(width: 2),
                      Icon(
                        DashboardIcons.openModule,
                        size: 16,
                        color: DashboardColors.faintInk(context),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                if (measured == null)
                  Text(
                    emptyNote,
                    style: text.labelSmall?.copyWith(
                      color: DashboardColors.faintInk(context),
                    ),
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: measured.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: DashboardColors.well(context),
                      valueColor: AlwaysStoppedAnimation(tone),
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: AppSpacing.medium,
                      runSpacing: 2,
                      children: [
                        for (final note in notes)
                          Text(
                            note,
                            style: text.labelSmall?.copyWith(
                              color: DashboardColors.mutedInk(context),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: body),
    );
  }

  static String _percent(double ratio) => '${(ratio * 100).round()}%';
}

/// A run of short figures as one divided strip — Home's roster and money
/// strips, which is what this page uses instead of another grid of boxes.
///
/// They are the same kind of measurement read across, so stacking them into
/// rows would turn one reading into four.
class OverviewCellStrip extends StatelessWidget {
  const OverviewCellStrip({super.key, required this.cells});

  final List<OverviewCell> cells;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Four money cells need more room than four counts; below this the
        // strip wraps into two rows rather than eliding every value.
        final perCell =
            constraints.maxWidth / (cells.isEmpty ? 1 : cells.length);
        final split =
            cells.length > 2 &&
            perCell < MediaQuery.textScalerOf(context).scale(120);

        if (!split) return _Row(cells: cells);

        final half = (cells.length / 2).ceil();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row(cells: cells.sublist(0, half)),
            const SizedBox(height: AppSpacing.small),
            _Row(cells: cells.sublist(half)),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.cells});

  final List<OverviewCell> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          Expanded(child: cells[i]),
          if (i != cells.length - 1)
            Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
              color: DashboardColors.divider(context),
            ),
        ],
      ],
    );
  }
}

/// One cell of an [OverviewCellStrip]: a glyph and caption on one line, the
/// figure under it, and an optional note.
class OverviewCell extends StatelessWidget {
  const OverviewCell({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.tone,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;

  /// Tints the figure. Reserve it for a value that carries a verdict — money
  /// owed, an overdue count. An all-tinted strip says nothing.
  final Color? tone;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: DashboardColors.mutedInk(context)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: tone,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (note != null)
            Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: DashboardColors.faintInk(context),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: body,
    );
  }
}

/// A record inside a panel: a tinted glyph square, a title, what it means, a
/// figure and a way in. Home's queue tile, to the pixel — the attention panel
/// and the quick-action list are the same kind of record and now read as one.
class OverviewRecordTile extends StatelessWidget {
  const OverviewRecordTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.value,
    this.onTap,
    this.titleLines = 1,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppStatusTone tone;
  final String? value;
  final VoidCallback? onTap;
  final int titleLines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = DashboardColors.status(context, tone);
    final radius = BorderRadius.circular(10);

    return Material(
      // The nested-tile step of the surface ladder, not the panel's own tone:
      // a record drawn in the panel's colour is a box outlined on the very
      // surface it sits on, which is the card-in-card the design system
      // rejects. One step up, it reads as a thing *inside* the card.
      color: DashboardColors.nested(context),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: DashboardColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.tint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DashboardColors.statusLine(context, tone),
                  ),
                ),
                child: Icon(icon, size: 18, color: style.ink),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: titleLines,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: titleLines > 1 ? 1.25 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Text(
                  value!,
                  style: text.titleMedium?.copyWith(
                    color: style.ink,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              if (onTap != null)
                Icon(
                  DashboardIcons.openModule,
                  size: 18,
                  color: DashboardColors.faintInk(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single line inside a panel — glyph, label, a figure, a way in. Home's
/// "needs a reply" row, used here for a reading that is neither a ratio nor a
/// queue.
class OverviewLinkRow extends StatelessWidget {
  const OverviewLinkRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.note,
    this.tone,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  /// A short qualifier under the figure — a verdict word, a window.
  final String? note;

  final Color? tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(8);

    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: tone ?? DashboardColors.mutedInk(context),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tone,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (note != null)
                Text(
                  note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: DashboardColors.faintInk(context),
                  ),
                ),
            ],
          ),
          if (onTap != null)
            Icon(
              DashboardIcons.openModule,
              size: 16,
              color: DashboardColors.faintInk(context),
            ),
        ],
      ),
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: body),
    );
  }
}

/// The column rule for a run of [OverviewRecordTile]s inside a panel — Home's,
/// including its breakpoints, so a queue tile is the same width on both pages.
class OverviewTileGrid extends StatelessWidget {
  const OverviewTileGrid({
    super.key,
    required this.children,
    this.rowHeight = 72,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double rowHeight;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final fitted = constraints.maxWidth >= scaler.scale(760)
            ? 3
            : constraints.maxWidth >= scaler.scale(480)
            ? 2
            : 1;
        final columns = fitted > maxColumns ? maxColumns : fitted;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.small,
            mainAxisExtent: rowHeight * scaler.scale(1).clamp(1.0, 2.0),
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// The panel action Home uses everywhere: a plain text button with a short
/// label — «التفاصيل», «كل المسارات». No leading chevron; the rows underneath
/// already carry one each, and a second glyph in the header is noise.
class OverviewPanelAction extends StatelessWidget {
  const OverviewPanelAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}

/// One term of an equation read across a panel — label above, figure below, in
/// the strip cell's own type so the panel reads as one surface.
class OverviewFigure extends StatelessWidget {
  const OverviewFigure({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (emphasised ? text.titleMedium : text.titleSmall)?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// An operator bound to the [OverviewFigure] it applies to, so a wrap at a
/// narrow width never orphans a lone «=» at the head of a line.
class OverviewTerm extends StatelessWidget {
  const OverviewTerm({
    super.key,
    required this.symbol,
    required this.label,
    required this.value,
    this.color,
    this.emphasised = false,
  });

  final String symbol;
  final String label;
  final String value;
  final Color? color;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            symbol,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: DashboardColors.faintInk(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        OverviewFigure(
          label: label,
          value: value,
          color: color,
          emphasised: emphasised,
        ),
      ],
    );
  }
}
