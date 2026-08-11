import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The heading above each block of an office profile.
///
/// The glyph and the count are the working parts: two stacked lists of cards
/// read as one undifferentiated scroll without a mark to tell them apart, and a
/// rider deciding whether to keep scrolling wants the size of the list before
/// they enter it.
///
/// The glyph sits in a filled brand tile rather than floating as a bare icon —
/// at 28px on its own it read as a button someone forgot to make tappable.
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
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            
            color: ClientColors.primaryFillFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.sm),
            boxShadow: ClientElevation.sm(context),
          ),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
        const SizedBox(width: ClientSpacing.sm),
        Flexible(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: ClientSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ClientColors.primaryContainerFor(context),
              borderRadius: BorderRadius.circular(ClientRadius.pill),
            ),
            child: Text(
              '$count',
              style: ClientTypography.labelMedium(context).copyWith(
                fontWeight: FontWeight.w900,
                color: ClientColors.onPrimaryContainerFor(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
