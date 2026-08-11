import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';
import '../utils/captain_text_direction.dart';

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

  final String? value;

  final String? detail;

  final Widget? trailing;
  final VoidCallback? onTap;

  final Color? accentColor;

  final Color? iconColor;

  final bool valueIsIdentifier;

  final bool showChevron;

  static const double _valueWidthShare = 0.62;

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
              SizedBox(
                width: value != null || trailing != null
                    ? CaptainDesignTokens.s4
                    : CaptainDesignTokens.s12,
              ),
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

class _Value extends StatelessWidget {
  const _Value({required this.row, required this.maxWidth});

  final CaptainListRow row;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      row.value!,
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
      child: row.valueIsIdentifier
          ? Directionality(
              textDirection: CaptainTextDirection.ofIdentifier(row.value!),
              child: text,
            )
          : text,
    );
  }
}
