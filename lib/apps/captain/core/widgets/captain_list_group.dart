import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';
import '../utils/captain_text_direction.dart';

/// A grouped inset list: one surface holding several rows, split by hairlines
/// that start under the text rather than at the card edge.
///
/// Replaces the per-block "titled card" the captain screens used to stack. Five
/// framed cards down a page is a dashboard layout; one surface per *topic*,
/// named by a [CaptainSectionLabel] above it, is what a phone app does. The
/// group draws no border — separation comes from the page background and the
/// gaps between groups, not from an outline around every element.
class CaptainListGroup extends StatelessWidget {
  const CaptainListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br20,
        boxShadow: CaptainDesignTokens.softShadow(context),
      ),
      // So a row's ink splash is clipped to the group's rounded corners.
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const CaptainRowDivider(),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// The hairline between two [CaptainListRow]s. Inset to clear the leading icon
/// column so the rows read as one list instead of as stacked slabs.
class CaptainRowDivider extends StatelessWidget {
  const CaptainRowDivider({super.key, this.indent = 52});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      color: CaptainColors.dividerFor(context).withValues(alpha: 0.7),
    );
  }
}

/// One row inside a [CaptainListGroup]: a leading icon, a label, and either a
/// value or a caller-supplied trailing widget.
///
/// The label and the value are sized *against each other* rather than splitting
/// the row down the middle. The value is measured first and takes only the width
/// it needs, pinned to the trailing edge; the label takes what is left. That
/// ordering is deliberate — the value is the answer the captain opened the
/// screen for, and clipping a licence number or a plate shows a *different*
/// number, while clipping a label costs a word they already know. The label
/// therefore gives way first, and [_valueWidthShare] caps how much of the row a
/// long value may claim so it can never squeeze the label out entirely.
class CaptainListRow extends StatelessWidget {
  const CaptainListRow({
    super.key,
    required this.label,
    this.icon,
    this.value,
    this.detail,
    this.trailing,
    this.onTap,
    this.accentColor,
    this.iconColor,
    this.valueIsIdentifier = false,
    this.showChevron = false,
  });

  final String label;
  final IconData? icon;

  /// The row's answer, rendered at the trailing edge. Omit when [trailing]
  /// carries the row's content instead.
  final String? value;

  /// A second, quieter line under [label] — the "why" behind a status.
  final String? detail;

  final Widget? trailing;
  final VoidCallback? onTap;

  /// Tints the icon and the label. Left null the row reads as neutral; set it
  /// for rows that *are* a status (a valid licence, an expired one) or that are
  /// destructive.
  final Color? accentColor;

  /// Tints the leading icon alone, leaving the label neutral. For rows that are
  /// *actions* rather than statuses: a coloured icon marks them as tappable
  /// without shouting the label at a captain scanning the list.
  final Color? iconColor;

  /// Set when [value] is an identifier rather than prose — a phone number, a
  /// licence number, a plate. Those resolve their own direction instead of
  /// inheriting the screen's RTL, which would reorder their runs into a
  /// different number than the one stored. See [CaptainTextDirection].
  final bool valueIsIdentifier;

  final bool showChevron;

  /// The most of a row's width a [value] may occupy before it starts
  /// ellipsising. Everything this app puts in a value — a phone number, a plate,
  /// a licence code, a date — fits well inside it at the default text scale, so
  /// the cap only ever engages for genuinely long text or a captain running a
  /// large system font. It exists so the label always keeps a readable column.
  static const double _valueWidthShare = 0.62;

  /// True when the row states a fact rather than offering an action. Those rows
  /// read as caption → answer: the label is a heading the captain already knows,
  /// so it steps back to let the value carry the row's weight. Tappable rows and
  /// status rows are excluded — there the *label* is the row's content, and
  /// muting it would hide the thing being tapped.
  bool get _isDataRow => value != null && onTap == null && accentColor == null;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    final detailText = detail;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s16,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color:
                    accent ??
                    iconColor ??
                    CaptainColors.textSecondaryFor(context),
              ),
              const SizedBox(width: CaptainDesignTokens.s16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaptainTypography.bodyMedium(context).copyWith(
                      color:
                          accent ??
                          (_isDataRow
                              ? CaptainColors.textSecondaryFor(context)
                              : CaptainColors.textPrimaryFor(context)),
                      fontWeight: accent == null
                          ? FontWeight.w600
                          : FontWeight.w800,
                    ),
                  ),
                  if (detailText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detailText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CaptainTypography.labelSmall(context).copyWith(
                        color: CaptainColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: CaptainDesignTokens.s12),
              _Value(
                row: this,
                maxWidth: constraints.maxWidth * _valueWidthShare,
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: CaptainDesignTokens.s12),
              trailing!,
            ],
            if (showChevron) ...[
              // Tight against a value it belongs to — "المظهر … تلقائي ›" is
              // one answer, not an answer and a separate control — and at the
              // full gap when it stands alone as the row's only affordance.
              SizedBox(
                width: value != null || trailing != null
                    ? CaptainDesignTokens.s4
                    : CaptainDesignTokens.s12,
              ),
              // Authored for LTR on purpose: Material's chevrons carry
              // `matchTextDirection`, so `Icon` flips this to point left under
              // the app's RTL. Naming the left one here would mirror it twice
              // and land the drill-in arrow pointing back out of the page.
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: CaptainColors.textSecondaryFor(context),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// The row's answer, sized to its own content and pinned to the trailing edge.
///
/// [maxWidth] is a ceiling, not a width: the box is loosely constrained, so a
/// short value takes only the space it needs and the label keeps the rest. It is
/// what stops a long value from pushing the row into an overflow, which is the
/// one failure the captain must never see mid-shift.
class _Value extends StatelessWidget {
  const _Value({required this.row, required this.maxWidth});

  final CaptainListRow row;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      row.value!,
      // An identifier holds its single line: broken across two, a phone number
      // reads as two numbers. Prose — a vehicle model, a status word — would
      // rather wrap than lose its tail to an ellipsis.
      maxLines: row.valueIsIdentifier ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: CaptainTypography.bodyMedium(context).copyWith(
        color: CaptainColors.textPrimaryFor(context),
        fontWeight: FontWeight.w800,
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      // The Directionality wraps only the text, never its position: the value's
      // own characters resolve their own direction, while where it sits on the
      // row stays the ambient direction's call — so a latin phone number keeps
      // hugging the trailing edge of an RTL row instead of jumping back against
      // the label.
      child: row.valueIsIdentifier
          ? Directionality(
              textDirection: CaptainTextDirection.ofIdentifier(row.value!),
              child: text,
            )
          : text,
    );
  }
}
