import 'package:flutter/material.dart';

import '../../../core/widgets/route_direction_text.dart';
import '../landing_content.dart';
import '../theme/landing_theme.dart';
import 'landing_atoms.dart';
import 'landing_charts.dart';

/// The three screens inside the hero rig, drawn rather than photographed.
///
/// The rest of the page embeds real captures of the shipping apps, and it
/// should keep doing that — a photograph cannot promise a screen the product
/// does not have. The fold is the one place where that trade goes the other
/// way: a console capture shown at a third of its real width is a wall of 9px
/// type, and the first thing a visitor sees should be legible. So these three
/// boards state the *reduced* version of each screen — four numbers, three
/// trips, one chart on the console; one card each on the phones — at a size a
/// reader takes in at a glance, and every screen that carries detail is
/// photographed further down.
///
/// Each board is authored at a fixed design width and scaled to whatever the
/// rig gives it, exactly the way a screenshot would be. That is what keeps
/// the page's 320→1600 sweep clean without a single responsive branch inside
/// a board: a scaled board cannot overflow, and its aspect ratio is the same
/// at every width, so the fold does not reflow as the window moves.

/// The console board's authoring width. Close to the width the rig hands it
/// on a desktop screen, so the type is drawn at very nearly 1:1 there.
const double _consoleWidth = 780;

/// The phone boards' authoring width — the screen, not the device: the body
/// and its bezel are drawn around this by [LandingPhoneFrame].
const double _phoneWidth = 220;

/// Pins a delta's leading figure left-to-right.
///
/// `+3 عن أمس` lays itself out as `3+ عن أمس` in an RTL paragraph: `+` is a
/// neutral, so the bidi algorithm hands it to the Arabic run beside it rather
/// than to the number it belongs to, and the tile then states a figure that
/// looks like a footnote marker. A *first-strong* isolate cannot fix this —
/// `+3` holds no strong character for it to find — so the figure is wrapped
/// in an explicit LTR isolate (U+2066 … U+2069, both of which render as
/// nothing). Same bug class as `routeDirectionLabel`.
String _isolatedFigure(String text) {
  final match = _leadingFigure.firstMatch(text);
  if (match == null) return text;
  return '\u2066${match[0]}\u2069${text.substring(match.end)}';
}

final _leadingFigure = RegExp(r'^[+\-−]?[\d.,]+%?');

/// Draws [child] at [width] and scales the result to fit the space given.
class _Board extends StatelessWidget {
  const _Board({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      // Symmetric, so it means the same thing in both directions — an
      // `AlignmentDirectional` here would flip the board with the page.
      alignment: Alignment.topCenter,
      child: SizedBox(width: width, child: child),
    );
  }
}

// ── The console ───────────────────────────────────────────────────────────

/// The office console, reduced to the one screen that answers "how is today
/// going": the day's four numbers, the trips still to run, and the week's
/// bookings.
class LandingConsoleBoard extends StatelessWidget {
  const LandingConsoleBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Board(
      width: _consoleWidth,
      child: ColoredBox(
        color: LandingPalette.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ConsoleHeader(),
            Padding(
              padding: EdgeInsets.fromLTRB(21, 18, 21, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ConsoleOverviewRow(),
                  SizedBox(height: 16),
                  _ConsoleKpiRow(),
                  SizedBox(height: 14),
                  _ConsolePanels(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The navy strip naming the office and stamping the board as live.
class _ConsoleHeader extends StatelessWidget {
  const _ConsoleHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: LandingPalette.navy,
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Row(
        children: [
          const Icon(
            Icons.dashboard_rounded,
            size: 14,
            color: LandingPalette.onNavyAccent,
          ),
          const SizedBox(width: 8),
          // The title takes the slack instead of a `Spacer`, so a face wider
          // than Cairo clips the office name rather than shoving the stamp
          // off the end of the strip.
          Expanded(
            child: Text(
              LandingContent.boardConsoleTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LandingType.label(
                13,
                color: LandingPalette.surface,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: LandingPalette.live,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              LandingContent.boardConsoleStamp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LandingType.label(
                10.5,
                color: LandingPalette.surface.withValues(alpha: 0.7),
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «نظرة عامة» and the period the board is reporting on.
class _ConsoleOverviewRow extends StatelessWidget {
  const _ConsoleOverviewRow();

  @override
  Widget build(BuildContext context) {
    const periods = LandingContent.boardPeriods;
    return Row(
      children: [
        Expanded(
          child: Text(
            LandingContent.boardOverview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.cardTitle(17),
          ),
        ),
        const SizedBox(width: 10),
        for (var i = 0; i < periods.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          _PeriodPill(label: periods[i], active: i == 0),
        ],
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: active ? LandingPalette.brand : LandingPalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? LandingPalette.brand : LandingPalette.border,
        ),
      ),
      child: Text(
        label,
        style: LandingType.label(
          11,
          color: active ? LandingPalette.surface : LandingPalette.muted,
          weight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// The day's four numbers.
class _ConsoleKpiRow extends StatelessWidget {
  const _ConsoleKpiRow();

  @override
  Widget build(BuildContext context) {
    const kpis = LandingContent.boardKpis;
    // A stated height rather than an intrinsic one: the four cards carry
    // different amounts of text and a row of unequal tiles is the first thing
    // that makes a drawn board look drawn.
    return SizedBox(
      height: 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < kpis.length; i++) ...[
            if (i > 0) const SizedBox(width: 11),
            Expanded(child: _KpiCard(kpi: kpis[i])),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final LandingKpi kpi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: LandingPalette.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LandingPalette.border),
      ),
      child: Column(
        // Not a `Spacer`: the board is measured under unbounded height in the
        // page's grid rows, where a flex child asserts.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kpi.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.label(11.5, weight: FontWeight.w700),
                ),
              ),
              if (kpi.icon != null) ...[
                const SizedBox(width: 6),
                Icon(kpi.icon, size: 14, color: LandingPalette.faint),
              ],
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  kpi.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.metric(26, color: kpi.valueColor),
                ),
              ),
              if (kpi.unit.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(
                  kpi.unit,
                  style: LandingType.label(11, weight: FontWeight.w700),
                ),
              ],
            ],
          ),
          Text(
            _isolatedFigure(kpi.delta),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.label(
              10.5,
              color: kpi.deltaColor,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The two panels under the numbers: what is still to run today, and how the
/// week has booked.
class _ConsolePanels extends StatelessWidget {
  const _ConsolePanels();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 236,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 48, child: _TripsPanel()),
          SizedBox(width: 13),
          Expanded(flex: 52, child: _BookingsPanel()),
        ],
      ),
    );
  }
}

/// A panel's tinted title strip.
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: const BoxDecoration(
        color: LandingPalette.surface2,
        border: Border(bottom: BorderSide(color: LandingPalette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LandingType.cardTitle(12.5),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: trailing),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.header, required this.body});

  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: EdgeInsets.zero,
      clip: true,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _TripsPanel extends StatelessWidget {
  const _TripsPanel();

  @override
  Widget build(BuildContext context) {
    const trips = LandingContent.boardTrips;
    return _Panel(
      header: _PanelHeader(
        title: LandingContent.boardTripsTitle,
        trailing: Text(
          LandingContent.boardTripsAction,
          style: LandingType.label(
            11,
            color: LandingPalette.brandInk,
            weight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < trips.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: LandingPalette.borderSoft,
              ),
            Expanded(child: _TripRow(trip: trips[i])),
          ],
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});

  final LandingBoardTrip trip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RouteDirectionText(
                  origin: trip.origin,
                  destination: trip.destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.cardTitle(12),
                  connectorStyle: LandingType.label(
                    12,
                    color: LandingPalette.faint,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  trip.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.label(
                    10.5,
                    color: LandingPalette.faint,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // `12 / 14` is a Latin run: left to the RTL paragraph it can come
          // out reversed. Centred in its own cell, so isolating it cannot
          // drift it out from under the column above.
          SizedBox(
            width: 42,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  trip.seats,
                  maxLines: 1,
                  softWrap: false,
                  style: LandingType.label(11.5, weight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          LandingBadge(label: trip.status, tone: trip.tone, dense: true),
        ],
      ),
    );
  }
}

class _BookingsPanel extends StatelessWidget {
  const _BookingsPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      header: _PanelHeader(
        title: LandingContent.boardChartTitle,
        trailing: Text(
          LandingContent.boardChartTotal,
          style: LandingType.label(10.5, weight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
        // The chart keeps its designed aspect and hangs from the baseline, so
        // the headroom above the tallest bar is headroom rather than stretch.
        child: const Align(
          alignment: Alignment.bottomCenter,
          child: LandingBarChart(
            heights: LandingContent.boardChartHeights,
            labels: LandingContent.boardChartLabels,
          ),
        ),
      ),
    );
  }
}

// ── The phones ────────────────────────────────────────────────────────────

/// The shared shape of both phone screens: a navy head carrying the app's
/// current subject, and a paper foot carrying the one card it acts on.
class _PhoneBoard extends StatelessWidget {
  const _PhoneBoard({required this.head, required this.foot});

  final List<Widget> head;
  final List<Widget> foot;

  @override
  Widget build(BuildContext context) {
    return _Board(
      width: _phoneWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: LandingPalette.navy,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: head,
            ),
          ),
          Container(
            color: LandingPalette.surface,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: foot,
            ),
          ),
        ],
      ),
    );
  }
}

/// The rider app: where the next trip is searched for, and the booking
/// already made.
class LandingRiderBoard extends StatelessWidget {
  const LandingRiderBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhoneBoard(
      head: [
        Text(
          LandingContent.boardRiderApp,
          style: LandingType.label(
            9.5,
            color: LandingPalette.surface.withValues(alpha: 0.6),
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          LandingContent.boardRiderTitle,
          style: LandingType.cardTitle(14.5, color: LandingPalette.surface),
        ),
        const SizedBox(height: 13),
        Container(
          decoration: BoxDecoration(
            color: LandingPalette.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            children: [
              _PhoneField(
                icon: Icons.my_location_rounded,
                label: LandingContent.boardRiderFrom,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: LandingPalette.borderSoft,
                indent: 11,
                endIndent: 11,
              ),
              _PhoneField(
                icon: Icons.place_rounded,
                label: LandingContent.boardRiderTo,
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        const _PhoneButton(
          icon: Icons.search_rounded,
          label: LandingContent.boardRiderSearch,
        ),
      ],
      foot: [
        Text(
          LandingContent.boardRiderBooking,
          style: LandingType.label(
            9.5,
            color: LandingPalette.brandInk,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: LandingPalette.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LandingPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RouteDirectionText(
                origin: LandingContent.boardRiderOrigin,
                destination: LandingContent.boardRiderDestination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LandingType.cardTitle(11.5),
                connectorStyle: LandingType.label(
                  11.5,
                  color: LandingPalette.faint,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                LandingContent.boardRiderDepart,
                style: LandingType.cardBody(
                  9,
                  color: LandingPalette.faint,
                ).copyWith(height: 1.55),
              ),
              const SizedBox(height: 9),
              const Row(
                children: [
                  Flexible(
                    child: LandingBadge(
                      label: LandingContent.boardRiderSeat,
                      tone: LandingTone.brand,
                      dense: true,
                    ),
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: LandingBadge(
                      label: LandingContent.boardRiderStatus,
                      tone: LandingTone.neutral,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        const _PhoneButton(
          icon: Icons.near_me_rounded,
          label: LandingContent.boardRiderTrack,
          outlined: true,
        ),
      ],
    );
  }
}

/// The captain app: the trip being driven, and the stop it is heading for.
class LandingCaptainBoard extends StatelessWidget {
  const LandingCaptainBoard({super.key});

  @override
  Widget build(BuildContext context) {
    const chips = LandingContent.boardCaptainChips;
    return _PhoneBoard(
      head: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: LandingPalette.live,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                LandingContent.boardCaptainLive,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LandingType.label(
                  9.5,
                  color: LandingPalette.surface.withValues(alpha: 0.7),
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RouteDirectionText(
          origin: LandingContent.boardCaptainOrigin,
          destination: LandingContent.boardCaptainDestination,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LandingType.cardTitle(15, color: LandingPalette.surface),
          connectorStyle: LandingType.label(
            15,
            color: LandingPalette.surface.withValues(alpha: 0.45),
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          LandingContent.boardCaptainVehicle,
          style: LandingType.label(
            9.5,
            color: LandingPalette.surface.withValues(alpha: 0.6),
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 7),
              Expanded(
                child: _CaptainChip(
                  value: chips[i].value,
                  label: chips[i].label,
                ),
              ),
            ],
          ],
        ),
      ],
      foot: [
        Text(
          LandingContent.boardCaptainNext,
          style: LandingType.label(
            9.5,
            color: LandingPalette.brandInk,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: LandingPalette.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LandingPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 12,
                    color: LandingPalette.brand,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      LandingContent.boardCaptainStop,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LandingType.cardTitle(11.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                LandingContent.boardCaptainEta,
                style: LandingType.label(
                  9,
                  color: LandingPalette.faint,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        const _CaptainProgress(),
        const SizedBox(height: 12),
        const _PhoneButton(
          icon: Icons.where_to_vote_rounded,
          label: LandingContent.boardCaptainCta,
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        child: Row(
          children: [
            Icon(icon, size: 12, color: LandingPalette.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LandingType.label(
                  11.5,
                  color: LandingPalette.ink,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptainChip extends StatelessWidget {
  const _CaptainChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LandingPalette.surface.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: LandingPalette.surface.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // `2 / 5` and `13:00` are Latin runs; centred here, so isolating
          // them cannot drift them off the chip's own centre line. Scaled
          // down rather than wrapped: `7 / 11` has two break opportunities in
          // it, and a chip narrow enough to take one folds to two lines and
          // bursts its own height.
          Directionality(
            textDirection: TextDirection.ltr,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: LandingType.label(
                  11.5,
                  color: LandingPalette.surface,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: LandingType.label(
                8.5,
                color: LandingPalette.surface.withValues(alpha: 0.55),
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// How far along the route the vehicle is — the bar fills from the start
/// edge, which in RTL is the right.
class _CaptainProgress extends StatelessWidget {
  const _CaptainProgress();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LandingPalette.well,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: LandingContent.boardCaptainProgress,
                  // A childless `DecoratedBox` takes `constraints.smallest`:
                  // without this the fill paints nothing at all.
                  heightFactor: 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: LandingPalette.brand,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          LandingContent.boardCaptainProgressLabel,
          style: LandingType.label(9.5, weight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// The one action a phone screen offers — filled on the navy head, outlined
/// on the paper foot.
class _PhoneButton extends StatelessWidget {
  const _PhoneButton({
    required this.icon,
    required this.label,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final foreground = outlined ? LandingPalette.ink : LandingPalette.surface;
    return Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: outlined ? LandingPalette.surface : LandingPalette.brand,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: outlined ? LandingPalette.border : LandingPalette.brand,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LandingType.label(
                11,
                color: foreground,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
