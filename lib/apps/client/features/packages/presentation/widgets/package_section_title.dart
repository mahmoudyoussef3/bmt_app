import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The heading above a block on the My Subscription pane.
///
/// A glyph in a filled brand tile, then the title — the same heading an office
/// profile puts above its departures and its routes, so two screens that both
/// stack titled cards read as one app rather than two.
class PackageSectionTitle extends StatelessWidget {
  const PackageSectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // The fill tone, not the ink tone: the glyph is white, and white on
            // the dark theme's accent blue misses contrast.
            color: ClientColors.primaryFillFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.sm),
            boxShadow: ClientElevation.sm(context),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
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
      ],
    );
  }
}
