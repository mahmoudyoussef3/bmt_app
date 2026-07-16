import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_avatar.dart';
import 'driver_profile_header_stats.dart';
import 'driver_profile_metrics.dart';
import 'driver_profile_rating_pill.dart';

/// The captain's identity block: avatar, name, standing and lifetime numbers,
/// all on the brand gradient.
///
/// The stats live here rather than in a card of their own — they *are* the
/// captain's identity on this screen, and hosting them on the header's gradient
/// leaves exactly one accent surface instead of a flat header competing with a
/// gradient card directly beneath it.
class DriverProfileHeader extends StatelessWidget {
  const DriverProfileHeader({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: DriverProfileMetrics.headerHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: CaptainColors.onPrimary,
      centerTitle: true,
      title: Text(
        'ملفي',
        style: CaptainTypography.titleMedium(
          context,
        ).copyWith(fontWeight: FontWeight.w800, color: CaptainColors.onPrimary),
      ),
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: CaptainColors.primaryGradient(context),
        ),
        child: Stack(
          children: [
            const _HeaderHighlight(),
            FlexibleSpaceBar(
              background: SafeArea(child: _HeaderContent(profile: profile)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Top clears the pinned toolbar the title sits in.
      padding: const EdgeInsets.fromLTRB(
        CaptainDesignTokens.s24,
        kToolbarHeight,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          DriverProfileAvatar(name: profile.name, photoUrl: profile.photoUrl),
          const SizedBox(height: CaptainDesignTokens.s12),
          Text(
            profile.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.titleLarge(context).copyWith(
              fontWeight: FontWeight.w900,
              color: CaptainColors.onPrimary,
            ),
          ),
          if (profile.hasRating) ...[
            const SizedBox(height: CaptainDesignTokens.s8),
            DriverProfileRatingPill(rating: profile.averageRating),
          ],
          const SizedBox(height: CaptainDesignTokens.s20),
          DriverProfileHeaderStats(
            totalTrips: profile.totalTrips,
            totalPassengers: profile.totalPassengers,
          ),
        ],
      ),
    );
  }
}

/// A soft highlight that keeps the large gradient from reading flat.
class _HeaderHighlight extends StatelessWidget {
  const _HeaderHighlight();

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: -80,
      end: -40,
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.white.withAlpha(40), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
