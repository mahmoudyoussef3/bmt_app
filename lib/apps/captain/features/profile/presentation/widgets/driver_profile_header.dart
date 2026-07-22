import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_avatar.dart';
import 'driver_profile_metrics.dart';
import 'driver_profile_rating_pill.dart';
import 'driver_profile_stats_card.dart';

/// The captain's identity, on the brand gradient.
///
/// This was a `SliverAppBar` that packed a 38px avatar, the name and a rating
/// pill onto one toolbar row — the account chip a web dashboard parks in its
/// corner. On a phone the profile screen *is* the person, so it now leads with
/// a large centred portrait, states the name under it, and closes with the two
/// lifetime totals the captain actually comes here to check.
///
/// It scrolls away rather than pinning. Identity is not a control the captain
/// needs within reach while reading their vehicle details, and pinning it would
/// cost the top of the screen on every scroll.
class DriverProfileHeader extends StatelessWidget {
  const DriverProfileHeader({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      // The gradient runs under the status bar, so its icons have to be light
      // regardless of the device's own theme.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            gradient: CaptainColors.primaryGradient(context),
            borderRadius: DriverProfileMetrics.heroRadius,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: DriverProfileMetrics.heroPadding,
              child: Column(
                children: [
                  DriverProfileAvatar(
                    name: profile.name,
                    photoUrl: profile.photoUrl,
                  ),
                  const SizedBox(height: CaptainDesignTokens.s16),
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CaptainTypography.headlineSmall(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: CaptainColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: CaptainDesignTokens.s12),
                  _Standing(profile: profile),
                  const SizedBox(height: CaptainDesignTokens.s24),
                  DriverProfileStatsCard(profile: profile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rating and office — who this captain is to the operation, in one wrapping
/// row so a long office name on a narrow phone drops to its own line instead
/// of squeezing the rating out.
class _Standing extends StatelessWidget {
  const _Standing({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final hasOffice = profile.officeName.isNotEmpty;
    if (!profile.hasRating && !hasOffice) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: CaptainDesignTokens.s8,
      runSpacing: CaptainDesignTokens.s8,
      children: [
        if (profile.hasRating)
          DriverProfileRatingPill(rating: profile.averageRating),
        if (hasOffice) _OfficePill(name: profile.officeName),
      ],
    );
  }
}

/// The office the captain drives for. Shown here rather than as an account row
/// because it is part of who they are, not a detail to look up.
class _OfficePill extends StatelessWidget {
  const _OfficePill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s4,
        CaptainDesignTokens.s12,
        CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: CaptainDesignTokens.brPill,
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.storefront_rounded,
            size: 15,
            color: CaptainColors.onPrimary,
          ),
          const SizedBox(width: CaptainDesignTokens.s4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(
                context,
              ).copyWith(color: CaptainColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
