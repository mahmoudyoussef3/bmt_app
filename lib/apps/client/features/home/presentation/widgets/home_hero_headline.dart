import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The hero's headline: the promise of the app, stated once — everything
/// else on Home (search, live trip, quick actions) exists to make it true.
///
/// Sized to stay a caption over the search card rather than a page of its
/// own: the subtitle is capped at two lines, so a long translation lengthens
/// the hero by a line rather than by a paragraph.
class HomeHeroHeadline extends StatelessWidget {
  const HomeHeroHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.home_heroHeadline,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingLarge(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.home_heroSubtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: Colors.white.withAlpha(200), height: 1.35),
        ),
      ],
    );
  }
}
