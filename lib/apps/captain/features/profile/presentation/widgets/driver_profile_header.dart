import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_avatar.dart';
import 'driver_profile_metrics.dart';
import 'driver_profile_rating_pill.dart';

/// The captain's identity bar: who they are and how they're rated, on the brand
/// gradient.
///
/// It reads as one row — avatar leading, name beside it, standing trailing —
/// inside a plain pinned toolbar. It carries identity only: the lifetime stats
/// it used to host live on `DriverProfileStatsCard` and the account facts on
/// `DriverProfileInfoCard`, because numbers on a plain surface are easier to
/// read than numbers on a gradient.
///
/// There is no separate 'ملفي' title anymore. It named the tab the captain had
/// just tapped, and keeping it meant paying an expanded height to stack it
/// above the identity row — most of the header's 176px was empty gradient.
class DriverProfileHeader extends StatelessWidget {
  const DriverProfileHeader({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      toolbarHeight: DriverProfileMetrics.toolbarHeight(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: CaptainColors.onPrimary,
      titleSpacing: CaptainDesignTokens.s24,
      title: Row(
        children: [
          DriverProfileAvatar(name: profile.name, photoUrl: profile.photoUrl),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.titleMedium(context).copyWith(
                fontWeight: FontWeight.w900,
                color: CaptainColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Centred because `AppBar` stretches its actions to the full toolbar
        // height, which would pull the pill into a tall slab.
        if (profile.hasRating)
          Center(child: DriverProfileRatingPill(rating: profile.averageRating)),
        const SizedBox(width: CaptainDesignTokens.s24),
      ],
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: CaptainColors.primaryGradient(context),
        ),
      ),
    );
  }
}
