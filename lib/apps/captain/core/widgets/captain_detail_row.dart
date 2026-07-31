import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';
import '../utils/captain_text_direction.dart';

/// A label paired with its value on one line, optionally led by an icon.
///
/// The truncation rule is the reason this is shared rather than re-inlined per
/// card: the label yields before the value does. A truncated "لوحة الترخيص"
/// still reads; a truncated plate number is useless. Neither may overflow —
/// these rows carry long values (models, plates, licence numbers) on narrow
/// phones, in Arabic, at arbitrary text scales.
///
/// That rule is enforced by the *order* the row is measured in: the value is
/// sized to its own content and pinned to the trailing edge, and the label takes
/// whatever is left. Giving the two of them a flex each instead splits the row
/// 50/50 no matter what they hold, which is how a plate ended up ellipsised
/// beside a four-letter label with empty space between them.
class CaptainDetailRow extends StatelessWidget {
  const CaptainDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.bottomSpacing = CaptainDesignTokens.s12,
    this.valueIsIdentifier = false,
  });

  final String label;
  final String value;

  /// Omitted by callers that already carry their own leading affordance.
  final IconData? icon;

  /// Trailing gap, so stacked rows space themselves without the parent
  /// interleaving separators. Pass `0` for a standalone row.
  final double bottomSpacing;

  /// Set when the value is an identifier rather than prose — a phone number, a
  /// licence number, a plate. Those lay out in their own direction instead of
  /// inheriting the screen's, which would otherwise reorder their runs into a
  /// different number than the one stored. See [CaptainTextDirection].
  final bool valueIsIdentifier;

  /// The most of a row's width a [value] may occupy before it starts
  /// ellipsising. It is a ceiling, not a width: a short value takes only what it
  /// needs. The cap exists so a long one can never squeeze the label out of the
  /// row entirely — or push the row into an overflow.
  static const double _valueWidthShare = 0.62;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomSpacing),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: CaptainColors.textSecondaryFor(context),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.bodyMedium(context).copyWith(
                  color: CaptainColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: CaptainDesignTokens.s12),
            _Value(
              value: value,
              isIdentifier: valueIsIdentifier,
              maxWidth: constraints.maxWidth * _valueWidthShare,
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({
    required this.value,
    required this.isIdentifier,
    required this.maxWidth,
  });

  final String value;
  final bool isIdentifier;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      value,
      // An identifier holds its single line: broken across two, a plate reads
      // as two plates. Prose — a route name, a status — would rather wrap than
      // lose its tail to an ellipsis.
      maxLines: isIdentifier ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: CaptainTypography.bodyMedium(context).copyWith(
        color: CaptainColors.textPrimaryFor(context),
        fontWeight: FontWeight.w700,
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      // The Directionality wraps only the text, never its position: the value's
      // own characters resolve their own direction, while where it sits on the
      // row stays the ambient direction's call — so a latin bus code keeps
      // hugging the trailing edge of an RTL row instead of jumping back against
      // the label.
      child: isIdentifier
          ? Directionality(
              textDirection: CaptainTextDirection.ofIdentifier(value),
              child: text,
            )
          : text,
    );
  }
}
