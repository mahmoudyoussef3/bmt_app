import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/landing_theme.dart';

/// CSS `clamp(min, Nvw, max)` in Dart.
///
/// The design sizes almost everything — section padding, headline sizes, the
/// content gutter — against the viewport width rather than at breakpoints, so
/// porting it faithfully needs the same primitive rather than a ladder of
/// `if (width < 720)` branches.
double landingClamp(
  BuildContext context, {
  required double min,
  required double vw,
  required double max,
}) {
  final value = MediaQuery.sizeOf(context).width * (vw / 100);
  return value.clamp(min, max);
}

/// `padding: 0 clamp(18px, 3.5vw, 36px)` — the page gutter.
double landingGutter(BuildContext context) =>
    landingClamp(context, min: 18, vw: 3.5, max: 36);

/// `padding: clamp(52px, 6.5vw, 92px) 0` — the standard section rhythm.
double landingSectionGap(BuildContext context) =>
    landingClamp(context, min: 52, vw: 6.5, max: 92);

/// The 1240px content column, centred, with the page gutter applied.
class LandingContainer extends StatelessWidget {
  const LandingContainer({
    super.key,
    required this.child,
    this.maxWidth = 1240,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: landingGutter(context)),
          child: child,
        ),
      ),
    );
  }
}

/// One page section: a background, optional hairline rules top and bottom,
/// and the vertical rhythm every section shares.
class LandingSection extends StatelessWidget {
  const LandingSection({
    super.key,
    required this.child,
    this.background,
    this.topBorder = false,
    this.bottomBorder = false,
    this.maxWidth = 1240,
    this.padTop = true,
    this.padBottom = true,
  });

  final Widget child;
  final Color? background;
  final bool topBorder;
  final bool bottomBorder;
  final double maxWidth;
  final bool padTop;
  final bool padBottom;

  @override
  Widget build(BuildContext context) {
    final gap = landingSectionGap(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          top: topBorder
              ? const BorderSide(color: LandingPalette.border)
              : BorderSide.none,
          bottom: bottomBorder
              ? const BorderSide(color: LandingPalette.border)
              : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.only(
        top: padTop ? gap : 0,
        bottom: padBottom ? gap : 0,
      ),
      child: LandingContainer(maxWidth: maxWidth, child: child),
    );
  }
}

/// CSS `grid-template-columns: repeat(auto-fit, minmax(min, 1fr))`.
///
/// Columns are whatever fits at [minItemWidth]; the remainder is shared out
/// so the last row still spans the full width, exactly as `1fr` does. Rows
/// size to their tallest child, which is why this is a [Wrap] of measured
/// widths rather than a [GridView] with a fixed extent.
class LandingAutoGrid extends StatelessWidget {
  const LandingAutoGrid({
    super.key,
    required this.minItemWidth,
    required this.children,
    this.spacing = 12,
    this.runSpacing,
    this.maxColumns,
    this.stretch = true,
  });

  final double minItemWidth;
  final List<Widget> children;
  final double spacing;
  final double? runSpacing;
  final int? maxColumns;

  /// When true every cell in a run is stretched to the tallest — the default,
  /// matching CSS grid. Set false for content that should hug its own height.
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        var columns = ((available + spacing) / (minItemWidth + spacing))
            .floor();
        columns = columns.clamp(1, children.length);
        if (maxColumns != null && columns > maxColumns!) columns = maxColumns!;
        final itemWidth = (available - spacing * (columns - 1)) / columns;

        if (!stretch) {
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing ?? spacing,
            children: [
              for (final child in children)
                SizedBox(width: itemWidth, child: child),
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          final slice = children.sublist(
            i,
            (i + columns).clamp(0, children.length),
          );
          rows.add(
            _EqualHeightRow(
              itemWidth: itemWidth,
              spacing: spacing,
              children: slice,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: runSpacing ?? spacing),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

/// A two-panel band that sits side by side when there is room and stacks when
/// there isn't — the design's `display:flex;flex-wrap:wrap` split sections.
///
/// [startFlex] / [endFlex] mirror the CSS `flex-grow` values so the split
/// keeps its proportions; [breakpoint] is the sum of the two CSS flex-bases,
/// i.e. the width below which the browser would wrap.
class LandingSplit extends StatelessWidget {
  const LandingSplit({
    super.key,
    required this.start,
    required this.end,
    required this.breakpoint,
    this.startFlex = 1,
    this.endFlex = 1,
    this.gap = 40,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.reverseWhenStacked = false,
  });

  final Widget start;
  final Widget end;
  final double breakpoint;
  final int startFlex;
  final int endFlex;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  /// Mirrors `flex-wrap: wrap-reverse` — the visual order flips when the row
  /// collapses, so the copy leads on a narrow screen and the mockup follows.
  final bool reverseWhenStacked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          final stacked = reverseWhenStacked ? [end, start] : [start, end];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              stacked.first,
              SizedBox(height: gap),
              stacked.last,
            ],
          );
        }
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Expanded(flex: startFlex, child: start),
            SizedBox(width: gap),
            Expanded(flex: endFlex, child: end),
          ],
        );
      },
    );
  }
}

/// One run of equal-height cells — CSS grid's default `align-items: stretch`.
///
/// The obvious spelling of this is `IntrinsicHeight` over a stretched [Row],
/// and it measures correctly, but it hands every cell *tight* constraints.
/// Tight constraints make a render object a relayout boundary, so when a font
/// arrives after first paint — which is exactly what `google_fonts` does, one
/// weight at a time — the re-wrapped paragraph's dirty mark stops at the cell
/// and never reaches the cached row height. The card then re-wraps to an extra
/// line inside a height frozen against the fallback face and overflows by
/// precisely one line.
///
/// So the row measures by real layout on every pass instead, and pins the
/// result as a *minimum* height rather than a tight one: cells still stretch
/// to the tallest, but a cell that turns out taller than the measurement grows
/// instead of overflowing, and nothing in the subtree becomes a relayout
/// boundary.
class _EqualHeightRow extends MultiChildRenderObjectWidget {
  const _EqualHeightRow({
    required this.itemWidth,
    required this.spacing,
    required super.children,
  });

  final double itemWidth;
  final double spacing;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEqualHeightRow(
        itemWidth: itemWidth,
        spacing: spacing,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEqualHeightRow renderObject,
  ) {
    renderObject
      ..itemWidth = itemWidth
      ..spacing = spacing
      ..textDirection = Directionality.of(context);
  }
}

class _EqualHeightParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualHeightRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualHeightParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualHeightParentData> {
  _RenderEqualHeightRow({
    required double itemWidth,
    required double spacing,
    required TextDirection textDirection,
  }) : _itemWidth = itemWidth,
       _spacing = spacing,
       _textDirection = textDirection;

  double _itemWidth;
  double get itemWidth => _itemWidth;
  set itemWidth(double value) {
    if (_itemWidth == value) return;
    _itemWidth = value;
    markNeedsLayout();
  }

  double _spacing;
  double get spacing => _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualHeightParentData) {
      child.parentData = _EqualHeightParentData();
    }
  }

  /// The width the run occupies: every cell at [itemWidth], separated by
  /// [spacing]. A short final run keeps its trailing gap empty rather than
  /// stretching, exactly as a grid's last row does.
  double get _runWidth =>
      childCount * itemWidth + (childCount - 1).clamp(0, childCount) * spacing;

  @override
  double computeMinIntrinsicWidth(double height) => _runWidth;

  @override
  double computeMaxIntrinsicWidth(double height) => _runWidth;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _tallest((RenderBox child) => child.getMinIntrinsicHeight(itemWidth));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _tallest((RenderBox child) => child.getMaxIntrinsicHeight(itemWidth));

  double _tallest(double Function(RenderBox child) measure) {
    var tallest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      tallest = math.max(tallest, measure(child));
    }
    return tallest;
  }

  BoxConstraints get _measureConstraints =>
      BoxConstraints(minWidth: itemWidth, maxWidth: itemWidth);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final height = _tallest(
      (RenderBox child) => child.getDryLayout(_measureConstraints).height,
    );
    return constraints.constrain(Size(_runWidth, height));
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.smallest;
      return;
    }

    // Pass 1 — measure every cell at its real width with the height free.
    var tallest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(_measureConstraints, parentUsesSize: true);
      tallest = math.max(tallest, child.size.height);
    }

    // Pass 2 — stretch to the tallest. `minHeight` rather than a tight height
    // keeps the cells off the relayout-boundary path and leaves room for one
    // to exceed the measurement, which is then absorbed on the retry below.
    var settled = 0.0;
    for (var attempt = 0; attempt < 2; attempt++) {
      final stretch = BoxConstraints(
        minWidth: itemWidth,
        maxWidth: itemWidth,
        minHeight: tallest,
      );
      settled = 0;
      for (var child = firstChild; child != null; child = childAfter(child)) {
        child.layout(stretch, parentUsesSize: true);
        settled = math.max(settled, child.size.height);
      }
      if (settled <= tallest) break;
      tallest = settled;
    }

    size = constraints.constrain(Size(_runWidth, settled));

    final rtl = textDirection == TextDirection.rtl;
    var index = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final offset = index * (itemWidth + spacing);
      (child.parentData! as _EqualHeightParentData).offset = Offset(
        rtl ? size.width - offset - itemWidth : offset,
        0,
      );
      index++;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
