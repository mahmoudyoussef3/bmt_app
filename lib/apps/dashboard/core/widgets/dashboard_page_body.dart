import 'package:flutter/material.dart';

/// The page frame every overview-shaped module scrolls inside.
///
/// The console's two live-read screens — الرئيسية and مركز العمليات المباشر —
/// are opened one after the other all day by the same person, so they may not
/// disagree about the size of their own margins. They used to: Home ran a
/// 24/32 page inset with 24px between bands while Live Ops ran a flat 16px
/// inset with 12px gaps, which is enough of a difference that switching modules
/// read as switching products even though every widget inside was shared.
///
/// The numbers now live here once, and both screens compose from the same two
/// parts: this body, and [DashboardBand] for a two-column row.
class DashboardPageBody extends StatelessWidget {
  const DashboardPageBody({super.key, required this.children});

  /// Page sections, in reading order. They are separated by [bandGap]
  /// automatically — a caller never inserts its own spacer between two of them.
  final List<Widget> children;

  /// The page inset. Vertical is deliberately larger than horizontal: the
  /// content already has the sidebar and the top bar framing it sideways, and
  /// what it needs is air above the title.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 32,
  );

  /// The gap between bands, and between the two panels of one band. One value
  /// so a band never reads as more closely related to the band under it than to
  /// its own other half.
  static const double bandGap = 24;

  /// Below this a [DashboardBand] stacks. Chosen so each column keeps ~380px —
  /// a trip row with time, route, crew and a seat bar stops being readable much
  /// under that.
  static const double splitBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: pagePadding,
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: bandGap),
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// One row of the page: a wider primary panel with a narrower companion,
/// stacking to full width when the window can no longer hold both.
///
/// Pair bands tall-with-tall — the departure board against the money panel, the
/// two short panels against each other. That is what stops one column running a
/// screen further than its neighbour.
class DashboardBand extends StatelessWidget {
  const DashboardBand({
    super.key,
    required this.main,
    required this.side,
    this.mainFlex = 3,
    this.sideFlex = 2,
  });

  final Widget main;
  final Widget side;
  final int mainFlex;
  final int sideFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < DashboardPageBody.splitBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              const SizedBox(height: DashboardPageBody.bandGap),
              side,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: mainFlex, child: main),
            const SizedBox(width: DashboardPageBody.bandGap),
            Expanded(flex: sideFlex, child: side),
          ],
        );
      },
    );
  }
}
