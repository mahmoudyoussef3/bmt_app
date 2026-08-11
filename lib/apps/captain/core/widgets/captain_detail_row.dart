import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';
import '../utils/captain_text_direction.dart';

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

  final IconData? icon;

  final double bottomSpacing;

  final bool valueIsIdentifier;

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
      child: isIdentifier
          ? Directionality(
              textDirection: CaptainTextDirection.ofIdentifier(value),
              child: text,
            )
          : text,
    );
  }
}
