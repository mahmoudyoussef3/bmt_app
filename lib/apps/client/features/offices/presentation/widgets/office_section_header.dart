import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The heading above each block of an office profile.
///
/// The glyph and the count are the working parts: three stacked lists of cards
/// read as one undifferentiated scroll without a mark to tell them apart, and a
/// rider deciding whether to keep scrolling wants the size of the list before
/// they enter it.
class OfficeSectionHeader extends StatelessWidget {
  const OfficeSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withAlpha(22),
            borderRadius: BorderRadius.circular(ClientRadius.xs),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: ClientSpacing.sm),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: ClientSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: ClientColors.surfaceMutedFor(context),
              borderRadius: BorderRadius.circular(ClientRadius.pill),
            ),
            child: Text(
              '$count',
              style: ClientTypography.labelSmall(context).copyWith(
                fontWeight: FontWeight.w900,
                color: ClientColors.textSecondaryFor(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
