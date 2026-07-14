import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// A titled group of hub rows, rendered as one card with hairline separators.
///
/// Grouping matters here: a flat list of fifteen identical rows gives the rider
/// nothing to scan by, whereas four labelled groups let them jump straight to
/// the one they came for.
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppLayout.spaceXs,
            right: AppLayout.spaceXs,
            bottom: AppLayout.spaceSm,
          ),
          child: Text(
            title.toUpperCase(),
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppLayout.spaceXs),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 56,
                    endIndent: AppLayout.spaceMd,
                    color: ClientColors.borderFor(context),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
