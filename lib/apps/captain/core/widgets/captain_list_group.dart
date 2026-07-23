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

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    final detailText = detail;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s16,
      ),
      child: Row(
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
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.bodyMedium(context).copyWith(
                    color: accent ?? CaptainColors.textPrimaryFor(context),
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
          const SizedBox(width: CaptainDesignTokens.s12),
          if (value != null) Expanded(child: _Value(row: this)),
          ?trailing,
          if (showChevron) ...[
            const SizedBox(width: CaptainDesignTokens.s4),
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
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.row});

  final CaptainListRow row;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      row.value!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: CaptainTypography.bodyMedium(context).copyWith(
        color: CaptainColors.textPrimaryFor(context),
        fontWeight: FontWeight.w800,
      ),
    );
    if (!row.valueIsIdentifier) return text;

    // The Align stays outside the Directionality on purpose. Only the value's
    // own characters resolve to their own direction; where the value sits on
    // the row is still decided by the ambient direction, so it keeps hugging
    // the row's trailing edge instead of jumping back against the label.
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Directionality(
        textDirection: CaptainTextDirection.ofIdentifier(row.value!),
        child: text,
      ),
    );
  }
}
