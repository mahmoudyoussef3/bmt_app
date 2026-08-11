import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

import '../../domain/entities/driver_profile.dart';
import 'driver_profile_avatar.dart';
import 'driver_profile_rating_pill.dart';
import 'driver_profile_stats_card.dart';

class DriverProfileIdentityCard extends StatelessWidget {
  const DriverProfileIdentityCard({super.key, required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s20,
        vertical: CaptainDesignTokens.s24,
      ),
      child: Column(
        children: [
          DriverProfileAvatar(name: profile.name, photoUrl: profile.photoUrl),
          if (profile.hasRating) ...[
            const SizedBox(height: CaptainDesignTokens.s16),
            DriverProfileRatingPill(rating: profile.averageRating),
          ],
          const SizedBox(height: CaptainDesignTokens.s24),
          DriverProfileStatsCard(profile: profile),
        ],
      ),
    );
  }
}
