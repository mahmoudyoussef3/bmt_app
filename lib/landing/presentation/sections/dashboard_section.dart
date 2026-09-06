import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_charts.dart';
import '../widgets/landing_layout.dart';
import '../widgets/landing_table.dart';

/// «لوحة التحكم» — the console itself, on the page's darkest band so the
/// white panel reads as a screen rather than as another card.
///
/// The tab rail is the section's only piece of state: it swaps the six KPIs
/// and the trend chart, leaving the line-occupancy panel and the trips table
/// in place, exactly as the design's `tabDefs` do.
class DashboardSection extends StatefulWidget {
  const DashboardSection({super.key});

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final gap = landingClamp(context, min: 52, vw: 6.5, max: 96);
    final tab = LandingContent.dashboardTabs[_tab];

    return ColoredBox(
      color: LandingPalette.navy,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _DashboardGlow())),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: gap),
            child: LandingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LandingSectionIntro(
                    eyebrow: LandingContent.dashboardEyebrow,
                    eyebrowColor: LandingPalette.onNavyAccent,
                    headline: LandingContent.dashboardHeadline,
                    lead: LandingContent.dashboardLead,
                    maxWidth: 660,
                    onDark: true,
                  ),
                  SizedBox(
                    height: landingClamp(context, min: 28, vw: 3.5, max: 44),
                  ),
                  _ConsolePanel(
                    tab: tab,
                    selected: _tab,
                    onSelect: (index) => setState(() => _tab = index),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `radial-gradient(800px 420px at 88% -5%, rgba(37,99,235,.3), transparent)`.
class _DashboardGlow extends CustomPainter {
  const _DashboardGlow();

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width * 0.88, size.height * -0.05);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                LandingPalette.brand.withValues(alpha: 0.3),
                LandingPalette.brand.withValues(alpha: 0),
              ],
              stops: const [0, 0.65],
            ).createShader(
              Rect.fromCenter(center: centre, width: 1600, height: 840),
            ),
    );
  }

  @override
  bool shouldRepaint(_DashboardGlow oldDelegate) => false;
}

class _ConsolePanel extends StatelessWidget {
  const _ConsolePanel({
    required this.tab,
    required this.selected,
    required this.onSelect,
  });

  final LandingDashboardTab tab;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final pad = landingClamp(context, min: 14, vw: 2, max: 20);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: LandingPalette.surface,
        borderRadius: BorderRadius.circular(LandingRadii.card + 8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xA6000000),
            offset: Offset(0, 46),
            blurRadius: 90,
            spreadRadius: -40,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabBar(selected: selected, onSelect: onSelect),
          Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The six figures are the only thing the tab rail changes
                // above the fold of the panel; crossfading them reads as the
                // console reloading rather than as a hard cut.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: LandingAutoGrid(
                    key: ValueKey(selected),
                    minItemWidth: 140,
                    spacing: 10,
                    children: [
                      for (final kpi in tab.kpis) _StatTile(stat: kpi),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LandingStretchRow(
                  // `flex: 1 1 320px` beside `flex: 1 1 200px` — never 50/50.
                  breakpoint: 532,
                  flex: const [320, 200],
                  children: [
                    _TrendCard(tab: tab),
                    const _TopLinesCard(),
                  ],
                ),
                const SizedBox(height: 12),
                const _TripsTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LandingPalette.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Text(
            LandingContent.dashboardPanelTitle,
            style: LandingType.metric(13.5).copyWith(letterSpacing: 0),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < LandingContent.dashboardTabs.length; i++)
                LandingPill(
                  label: LandingContent.dashboardTabs[i].label,
                  selected: i == selected,
                  onTap: () => onSelect(i),
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  unselectedBackground: LandingPalette.surface,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final LandingStat stat;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      background: LandingPalette.surface2,
      radius: 11,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.label(11),
          ),
          const SizedBox(height: 5),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.metric(20).copyWith(letterSpacing: -0.6),
          ),
          const SizedBox(height: 2),
          Text(
            landingIsolateFigures(stat.delta),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.label(
              10.5,
              color: stat.deltaColor,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.tab});

  final LandingDashboardTab tab;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
      radius: 12,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tab.chartTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.metric(13).copyWith(letterSpacing: 0),
                ),
              ),
              const SizedBox(width: 8),
              Text(tab.chartNote, style: LandingType.label(11)),
            ],
          ),
          const SizedBox(height: 12),
          LandingLineChart(points: tab.points),
        ],
      ),
    );
  }
}

class _TopLinesCard extends StatelessWidget {
  const _TopLinesCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      radius: 12,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LandingContent.dashboardTopLinesTitle,
            style: LandingType.metric(13).copyWith(letterSpacing: 0),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < LandingContent.dashboardTopLines.length; i++) ...[
            if (i > 0) const SizedBox(height: 13),
            _meterRow(LandingContent.dashboardTopLines[i]),
          ],
        ],
      ),
    );
  }

  Widget _meterRow(LandingMeterDatum datum) => LandingMeterRow(
    label: datum.name,
    value: datum.trailing,
    fraction: datum.fraction,
    color: datum.color,
  );
}

class _TripsTable extends StatelessWidget {
  const _TripsTable();

  @override
  Widget build(BuildContext context) {
    return LandingTable(
      minWidth: 540,
      header: [
        LandingTableHeaderCell(LandingContent.tripTableHeaders[0], width: 74),
        LandingTableHeaderCell(LandingContent.tripTableHeaders[1], flex: 1),
        LandingTableHeaderCell(LandingContent.tripTableHeaders[2], width: 96),
        LandingTableHeaderCell(LandingContent.tripTableHeaders[3], width: 74),
        LandingTableHeaderCell(LandingContent.tripTableHeaders[4], width: 70),
        LandingTableHeaderCell(LandingContent.tripTableHeaders[5], width: 78),
      ],
      rows: [
        for (final row in LandingContent.tripRows)
          [
            // A trip reference is a Latin run. The [Align] has to sit
            // *outside* the isolation: an LTR `Text` resolves its own
            // `TextAlign.start` to the left, which would slide the value out
            // from under its own column heading.
            SizedBox(
              width: 74,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  row.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: LandingType.label(12.5, weight: FontWeight.w800),
                ),
              ),
            ),
            Expanded(
              child: Text(
                row.line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LandingType.label(
                  12.5,
                  color: LandingPalette.ink,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              width: 96,
              child: Text(
                row.captain,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LandingType.label(12.5, weight: FontWeight.w600),
              ),
            ),
            SizedBox(
              width: 74,
              child: Text(
                row.time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LandingType.label(
                  12.5,
                  color: LandingPalette.ink,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 70,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  row.seats,
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                  style: LandingType.label(
                    12.5,
                    color: LandingPalette.ink,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 78,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LandingBadge(label: row.status, tone: row.tone),
              ),
            ),
          ],
      ],
    );
  }
}
