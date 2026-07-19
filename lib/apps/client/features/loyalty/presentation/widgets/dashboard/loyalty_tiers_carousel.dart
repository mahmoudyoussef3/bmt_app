import 'package:flutter/material.dart';

import '../../../domain/entities/loyalty_tier.dart';
import 'loyalty_tier_chip.dart';

/// Horizontally scrollable list of every membership level.
class LoyaltyTiersCarousel extends StatelessWidget {
  const LoyaltyTiersCarousel({
    super.key,
    required this.tiers,
    required this.currentTierName,
  });

  final List<LoyaltyTier> tiers;
  final String currentTierName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tiers.length,
        itemBuilder: (_, index) => LoyaltyTierChip(
          tier: tiers[index],
          isCurrent: tiers[index].name == currentTierName,
        ),
      ),
    );
  }
}
