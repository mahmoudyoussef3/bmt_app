import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «الأسئلة الشائعة» — a filtered, single-open accordion.
///
/// Nine questions in one flat run is a wall: the reader has to scan every row
/// to find the one that is theirs. So the rail narrows the list by topic and
/// each row carries its own topic while the rail is on «الكل» — the set reads
/// as four groups before anything is clicked, and clicking only shortens it.
///
/// One panel is open at a time, as in the design: nine answers expanded at
/// once would bury the closing CTA under them, and the reader is comparing
/// questions, not reading the set end to end.
class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  /// The rail's selection; `null` is «الكل».
  String? _category;

  /// An index into [LandingContent.faq] — the question's own identity rather
  /// than its position in the filtered run, so narrowing the rail can never
  /// move the open answer onto a different question.
  int _open = 0;

  /// The categories in the order the content authors them, which is also the
  /// order the questions run in.
  static final List<String> _categories = LandingContent.faq
      .map((entry) => entry.category)
      .toSet()
      .toList(growable: false);

  List<int> _indicesFor(String? category) => [
    for (final (index, entry) in LandingContent.faq.indexed)
      if (category == null || entry.category == category) index,
  ];

  void _selectCategory(String? category) {
    if (category == _category) return;
    setState(() {
      _category = category;
      final visible = _indicesFor(category);
      // The reader who narrows the rail should land on an answer rather than
      // on a run of closed rows, so the first question of the new set opens
      // unless the one they were already reading is still in it.
      if (!visible.contains(_open)) {
        _open = visible.isEmpty ? -1 : visible.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _indicesFor(_category);
    return Padding(
      padding: EdgeInsets.only(bottom: landingSectionGap(context)),
      child: LandingContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LandingSectionIntro(
              eyebrow: 'الدعم',
              headline: 'الأسئلة الشائعة',
              lead:
                  'إجابات مختصرة على أكثر ما يسأل عنه أصحاب مكاتب النقل قبل '
                  'البدء. اختر الموضوع اللي يهمك.',
              align: TextAlign.center,
              center: true,
              maxWidth: 560,
              headlineMin: 24,
              headlineVw: 3,
              headlineMax: 36,
            ),
            SizedBox(height: landingClamp(context, min: 20, vw: 2.6, max: 32)),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _FaqChip(
                  label: 'الكل',
                  count: LandingContent.faq.length,
                  selected: _category == null,
                  onTap: () => _selectCategory(null),
                ),
                for (final category in _categories)
                  _FaqChip(
                    label: category,
                    count: _indicesFor(category).length,
                    selected: _category == category,
                    onTap: () => _selectCategory(category),
                  ),
              ],
            ),
            SizedBox(height: landingClamp(context, min: 18, vw: 2.2, max: 28)),
            for (final (position, index) in visible.indexed) ...[
              if (position > 0) const SizedBox(height: 10),
              _FaqTile(
                question: LandingContent.faq[index].question,
                answer: LandingContent.faq[index].answer,
                // Redundant once the rail is narrowed to one topic.
                category: _category == null
                    ? LandingContent.faq[index].category
                    : null,
                open: _open == index,
                onTap: () =>
                    setState(() => _open = _open == index ? -1 : index),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One topic in the filter rail.
class _FaqChip extends StatefulWidget {
  const _FaqChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FaqChip> createState() => _FaqChipState();
}

class _FaqChipState extends State<_FaqChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? LandingPalette.brandTint
                  : _hovered
                  ? LandingPalette.raised
                  : LandingPalette.surface,
              borderRadius: LandingRadii.buttonR,
              border: Border.all(
                color: _focused
                    ? LandingPalette.brand
                    : selected
                    ? LandingPalette.brandLine
                    : LandingPalette.border,
              ),
              boxShadow: selected ? null : LandingPalette.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: LandingType.label(
                    13,
                    color: selected
                        ? LandingPalette.brandInk
                        : LandingPalette.muted,
                    weight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _arabicDigits(widget.count),
                  style: LandingType.label(
                    11.5,
                    color: selected
                        ? LandingPalette.brandInk.withValues(alpha: 0.65)
                        : LandingPalette.faint,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.category,
    required this.open,
    required this.onTap,
  });

  final String question;
  final String answer;

  /// The row's own topic, shown only while the rail is on «الكل».
  final String? category;
  final bool open;
  final VoidCallback onTap;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final open = widget.open;
    // Below this the question needs the whole row; the topic is already on
    // the rail above, so it is the part that goes.
    final showCategory =
        widget.category != null && MediaQuery.sizeOf(context).width >= 620;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: LandingPalette.surface,
        borderRadius: LandingRadii.cardR,
        border: Border.all(
          color: _focused
              ? LandingPalette.brand
              : open
              ? LandingPalette.brandLine
              : _hovered
              ? LandingPalette.borderStrong
              : LandingPalette.border,
        ),
        boxShadow: LandingPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The gesture is on the question row alone: the answer below is
          // meant to be read and selected, not to collapse under the cursor.
          Semantics(
            button: true,
            expanded: open,
            label: widget.question,
            child: FocusableActionDetector(
              mouseCursor: SystemMouseCursors.click,
              onShowHoverHighlight: (value) => setState(() => _hovered = value),
              onShowFocusHighlight: (value) => setState(() => _focused = value),
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onTap();
                    return null;
                  },
                ),
              },
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 13, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.question,
                          style: LandingType.label(
                            15,
                            color: LandingPalette.ink,
                            weight: FontWeight.w800,
                          ).copyWith(height: 1.5),
                        ),
                      ),
                      if (showCategory) ...[
                        const SizedBox(width: 14),
                        Text(
                          widget.category!,
                          style: LandingType.label(
                            11.5,
                            color: LandingPalette.faint,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      _FaqChevron(open: open, hovered: _hovered),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? Container(
                    width: double.infinity,
                    // No radius on this box: the tile above clips it, and a
                    // `BorderDirectional` cannot carry one anyway.
                    decoration: const BoxDecoration(
                      color: LandingPalette.surface2,
                      border: BorderDirectional(
                        top: BorderSide(color: LandingPalette.borderSoft),
                        start: BorderSide(
                          color: LandingPalette.brandLine,
                          width: 3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      18,
                      14,
                      18,
                      16,
                    ),
                    child: Text(
                      widget.answer,
                      style: LandingType.cardBody(13.5).copyWith(height: 1.9),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The chevron sits in a well of its own: on a row this wide a bare glyph
/// reads as a stray mark at the far edge rather than as the row's control.
class _FaqChevron extends StatelessWidget {
  const _FaqChevron({required this.open, required this.hovered});

  final bool open;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: open
            ? LandingPalette.brandTint
            : hovered
            ? LandingPalette.raised
            : LandingPalette.surface2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: open ? LandingPalette.brandLine : LandingPalette.border,
        ),
      ),
      child: AnimatedRotation(
        turns: open ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        child: Icon(
          Icons.expand_more_rounded,
          size: 19,
          color: open ? LandingPalette.brandInk : LandingPalette.muted,
        ),
      ),
    );
  }
}

/// The page writes indices and step numbers in Arabic-Indic digits and keeps
/// western digits for data and times; a rail count is an index, not a metric.
String _arabicDigits(int value) => value
    .toString()
    .split('')
    .map((digit) => String.fromCharCode(0x0660 + int.parse(digit)))
    .join();
