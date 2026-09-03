import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// `brandTint` at 55% over white — the answer column's band.
///
/// Kept lighter than [LandingPalette.brandTint] itself so the column header
/// and the closing bar stay the strongest brand marks in the card and the
/// seven body rows read as one quiet field behind them.
const _afterBand = Color(0xFFF3F7FE);

/// The row-header column's width, shared by the head and every body row so
/// the three columns line up without a real table layout.
const _axisWidth = 132.0;

/// «من إدارة مشتتة... إلى تشغيل منظم» — the before/after comparison.
///
/// Written as **one table**, not two lists: each row is an axis of the
/// operation with the complaint and its answer on the same line, so the
/// reader never has to pair a left item with a right one by counting. The
/// "after" column carries the brand tint and the card's only coloured rule,
/// which side is the destination is legible before a word of it is read.
class ComparisonSection extends StatelessWidget {
  const ComparisonSection({super.key});

  /// Below this the three columns stop fitting and each pair becomes its own
  /// card, which keeps a complaint and its answer together on a phone.
  static const _tableBreakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      maxWidth: 1040,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: 'الفرق',
            headline: 'من إدارة مشتتة... إلى تشغيل منظم',
            lead: LandingContent.comparisonLead,
            align: TextAlign.center,
            center: true,
            maxWidth: 720,
          ),
          SizedBox(height: landingClamp(context, min: 26, vw: 3.5, max: 42)),
          LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >= _tableBreakpoint
                ? const _ComparisonTable()
                : const _ComparisonStack(),
          ),
        ],
      ),
    );
  }
}

// ── Wide: one table ────────────────────────────────────────────────────────

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  @override
  Widget build(BuildContext context) {
    const rows = LandingContent.comparison;
    return LandingCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _TableHead(),
          for (final row in rows) _TableRow(row: row),
          const _OutcomeBar(),
        ],
      ),
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: _axisWidth,
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: LandingPalette.surface2,
              border: Border(bottom: BorderSide(color: LandingPalette.border)),
            ),
            child: Text('المحور', style: _axisStyle),
          ),
          const Expanded(
            child: _HeadCell(
              icon: Icons.error_outline_rounded,
              label: 'قبل EWT',
              tinted: false,
            ),
          ),
          const Expanded(
            child: _HeadCell(
              icon: Icons.check_circle_rounded,
              label: 'مع EWT',
              tinted: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  const _HeadCell({
    required this.icon,
    required this.label,
    required this.tinted,
  });

  final IconData icon;
  final String label;

  /// True for the "after" column, which is the one the section is selling.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: tinted ? LandingPalette.brandTint : LandingPalette.surface2,
        border: BorderDirectional(
          start: tinted
              ? const BorderSide(color: LandingPalette.brandLine)
              : const BorderSide(color: LandingPalette.borderSoft),
          bottom: BorderSide(
            color: tinted ? LandingPalette.brandLine : LandingPalette.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: tinted ? LandingPalette.brand : LandingPalette.muted,
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              label,
              style: LandingType.cardTitle(
                15,
                color: tinted ? LandingPalette.navy : LandingPalette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One axis of the operation: its label, the manual way, the platform way.
///
/// The row is stateful only to carry the hover highlight — at this width the
/// eye has to travel a long way from the complaint to its answer, and a band
/// that lights up under the pointer is what keeps the two on the same line.
class _TableRow extends StatefulWidget {
  const _TableRow({required this.row});

  final ({String axis, String before, String after}) row;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const rule = BorderSide(color: LandingPalette.borderSoft);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: _hoverDuration,
              width: _axisWidth,
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                color: _hovered
                    ? LandingPalette.raised
                    : LandingPalette.surface2,
                border: const Border(bottom: rule),
              ),
              child: Text(widget.row.axis, style: _axisStyle),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: _hoverDuration,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: _hovered
                      ? LandingPalette.surface2
                      : LandingPalette.surface,
                  border: const BorderDirectional(start: rule, bottom: rule),
                ),
                child: _Line(text: widget.row.before, answer: false),
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: _hoverDuration,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: _hovered ? LandingPalette.brandTint : _afterBand,
                  border: const BorderDirectional(
                    start: BorderSide(color: LandingPalette.brandLine),
                    bottom: rule,
                  ),
                ),
                child: _Line(text: widget.row.after, answer: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Narrow: a card per pair ────────────────────────────────────────────────

class _ComparisonStack extends StatelessWidget {
  const _ComparisonStack();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StackLegend(),
        for (final row in LandingContent.comparison) ...[
          const SizedBox(height: 12),
          _PairCard(row: row),
        ],
        const SizedBox(height: 12),
        const _OutcomeBar(standalone: true),
      ],
    );
  }
}

/// The table head, kept as a legend once the columns are gone.
///
/// Stacked, the tint and the tick are the only thing naming each half of a
/// pair card; two chips in the columns' own colours put the words back
/// without repeating them seven times.
class _StackLegend extends StatelessWidget {
  const _StackLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _LegendChip(
            icon: Icons.error_outline_rounded,
            label: 'قبل EWT',
            tinted: false,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _LegendChip(
            icon: Icons.check_circle_rounded,
            label: 'مع EWT',
            tinted: true,
          ),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.icon,
    required this.label,
    required this.tinted,
  });

  final IconData icon;
  final String label;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tinted ? LandingPalette.brandTint : LandingPalette.surface2,
        borderRadius: LandingRadii.buttonR,
        border: Border.all(
          color: tinted ? LandingPalette.brandLine : LandingPalette.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: tinted ? LandingPalette.brand : LandingPalette.muted,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: LandingType.cardTitle(
                13,
                color: tinted ? LandingPalette.navy : LandingPalette.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PairCard extends StatelessWidget {
  const _PairCard({required this.row});

  final ({String axis, String before, String after}) row;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(row.axis, style: _axisStyle),
                const SizedBox(height: 7),
                _Line(text: row.before, answer: false),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            decoration: const BoxDecoration(
              color: _afterBand,
              border: Border(top: BorderSide(color: LandingPalette.brandLine)),
            ),
            child: _Line(text: row.after, answer: true),
          ),
        ],
      ),
    );
  }
}

// ── Shared parts ───────────────────────────────────────────────────────────

/// One line of the comparison — the mark and the text.
///
/// The same widget draws both sides so a complaint and its answer share a
/// baseline, an icon box and a leading, and only weight and colour separate
/// them.
class _Line extends StatelessWidget {
  const _Line({required this.text, required this.answer});

  final String text;
  final bool answer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(
            answer ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: answer ? LandingPalette.brand : LandingPalette.faint,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: LandingType.label(
              13.5,
              color: answer ? LandingPalette.ink : LandingPalette.muted,
              weight: answer ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// The one-line takeaway the table adds up to, closing the card.
class _OutcomeBar extends StatelessWidget {
  const _OutcomeBar({this.standalone = false});

  /// True in the stacked layout, where it is its own card rather than the
  /// last band of the table.
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: LandingPalette.brandTint,
        borderRadius: standalone ? LandingRadii.cardR : null,
        border: standalone
            ? Border.all(color: LandingPalette.brandLine)
            : const Border(top: BorderSide(color: LandingPalette.brandLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.task_alt_rounded,
              size: 18,
              color: LandingPalette.brandInk,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              LandingContent.comparisonOutcome,
              style: LandingType.label(
                13.5,
                color: LandingPalette.navy,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _hoverDuration = Duration(milliseconds: 160);

final _axisStyle = LandingType.label(
  11.5,
  color: LandingPalette.faint,
  weight: FontWeight.w800,
).copyWith(letterSpacing: 0.2);
