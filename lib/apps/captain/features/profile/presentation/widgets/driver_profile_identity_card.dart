import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_avatar.dart';
import 'driver_profile_rating_pill.dart';

/// The one block on this screen that is about the captain rather than about a
/// field of their record: face, name, who they drive for, and the rating the
/// riders gave them.
///
/// It is a row, not a centred portrait — the profile is a page of facts, and a
/// full-width centred avatar block above them reads as a social profile rather
/// than as a work account. Everything else the screen knows is stated once, in
/// the grouped lists below, so nothing here is repeated further down.
class DriverProfileIdentityCard extends StatelessWidget {
  const DriverProfileIdentityCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      child: Row(
        children: [
          DriverProfileAvatar(name: profile.name, photoUrl: profile.photoUrl),
          const SizedBox(width: CaptainDesignTokens.s16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // The same size home draws the captain's name at, so their
                  // own name is one fixed thing across the app.
                  style: CaptainTypography.headlineSmall(context).copyWith(
                    color: CaptainColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                if (profile.officeName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.officeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaptainTypography.bodySmall(context).copyWith(
                      color: CaptainColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (profile.hasRating) ...[
                  const SizedBox(height: CaptainDesignTokens.s8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DriverProfileRatingPill(
                      rating: profile.averageRating,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
