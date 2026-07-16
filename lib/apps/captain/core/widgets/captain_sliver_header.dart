import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

/// The shared collapsing header for captain sub-screens — trip history, trip
/// execution, and the passenger manifest each hand-rolled this exact
/// `SliverAppBar` + `FlexibleSpaceBar` shape with slightly different heights,
/// paddings, and background-color sources before this existed. This is the
/// one copy; give it a title and an optional one-line subtitle.
///
/// Not for every collapsing header in the app — the Home dashboard's branded
/// greeting hero and the Profile screen's avatar hero are intentionally
/// distinct, richer heroes, not instances of this plain title+subtitle
/// pattern.
class CaptainSliverHeader extends StatelessWidget {
  const CaptainSliverHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: 88,
      backgroundColor: CaptainColors.surfaceFor(context),
      iconTheme: IconThemeData(color: CaptainColors.textPrimaryFor(context)),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.fromSTEB(
          CaptainDesignTokens.s24,
          CaptainDesignTokens.s16,
          CaptainDesignTokens.s24,
          CaptainDesignTokens.s16,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.titleLarge(context).copyWith(
                fontWeight: FontWeight.w800,
                color: CaptainColors.textPrimaryFor(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.labelMedium(
                  context,
                ).copyWith(color: CaptainColors.textSecondaryFor(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
