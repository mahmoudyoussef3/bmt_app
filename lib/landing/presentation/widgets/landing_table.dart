import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';

/// The bordered table the dashboard and bookings bands both wear: a raised
/// header strip over hairline-separated rows.
///
/// Its columns are stated in pixels, exactly as the design states them, so
/// below [minWidth] the table scrolls sideways inside its own card rather
/// than compressing columns that are already at their legible minimum. The
/// card itself never grows the page — only this strip moves.
class LandingTable extends StatelessWidget {
  const LandingTable({
    super.key,
    required this.minWidth,
    required this.header,
    required this.rows,
    this.radius = 12,
    this.borderColor = LandingPalette.border,
    this.shadow = const <BoxShadow>[],
    this.headerPadding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 10,
    ),
    this.rowPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    this.toolbar,
  });

  final double minWidth;

  /// The header cells, in start-to-end order.
  final List<Widget> header;

  /// One list of cells per row, in the same order as [header].
  final List<List<Widget>> rows;
  final double radius;
  final Color borderColor;
  final List<BoxShadow> shadow;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry rowPadding;

  /// An optional strip above the header — the bookings band's title and
  /// filter chips. It stays put while the columns scroll.
  final Widget? toolbar;

  @override
  Widget build(BuildContext context) {
    final table = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: headerPadding,
          decoration: BoxDecoration(
            color: LandingPalette.raised,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(children: header),
        ),
        for (final row in rows)
          Container(
            padding: rowPadding,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: LandingPalette.borderSoft),
              ),
            ),
            child: Row(children: row),
          ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: LandingPalette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?toolbar,
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= minWidth) return table;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: minWidth, child: table),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A header label — 11px, heavy, muted.
class LandingTableHeaderCell extends StatelessWidget {
  const LandingTableHeaderCell(this.label, {super.key, this.width, this.flex});

  final String label;
  final double? width;
  final int? flex;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: LandingType.label(11, weight: FontWeight.w800),
    );
    if (flex != null) return Expanded(flex: flex!, child: text);
    return SizedBox(width: width, child: text);
  }
}
