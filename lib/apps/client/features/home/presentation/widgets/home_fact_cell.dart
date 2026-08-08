import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One cell in a facts panel: an icon, a caption, then the value. Caption
/// above value so the eye lands on the value it came for — shared by every
/// facts panel on Home so a rider reading down a column of cards always
/// finds the same number in the same place.
class HomeFactCell extends StatelessWidget {
  const HomeFactCell({
    super.key,
    required this.icon,
    required this.caption,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String caption;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? ClientColors.textPrimaryFor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.sm,
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: ClientColors.textTertiaryFor(context),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    height: 1.2,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelLarge(
                    context,
                  ).copyWith(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
