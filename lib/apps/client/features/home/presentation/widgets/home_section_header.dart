import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Standard section intro on home: title + optional subtitle, with an
/// optional trailing "View all" action.
///
/// The action sits on the title's own line rather than beside the whole
/// block: a two-line intro used to drag the button down to the subtitle, so
/// the same control landed at a different height in every section. Pinning it
/// to the title gives the page one horizon that every header shares.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingMedium(context),
              ),
            ),
            if (hasAction) ...[
              const SizedBox(width: 8),
              _SectionAction(label: actionLabel!, onTap: onAction!),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ],
    );
  }
}

/// The header's "view all" link.
///
/// Its own widget so the negative inset that pulls the button's padding back
/// off the content edge stays in one place — without it the label hangs a
/// touch outside the column every other section aligns to.
class _SectionAction extends StatelessWidget {
  const _SectionAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: primary,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: primary, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 3),
          DirectionalIcon(
            Icons.arrow_forward_rounded,
            size: 15,
            color: primary,
          ),
        ],
      ),
    );
  }
}
