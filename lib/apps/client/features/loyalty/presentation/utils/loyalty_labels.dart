import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Localized display label for a loyalty tier name.
///
/// Tier names are stored verbatim in `loyalty_tiers.name` and matched against
/// the canonical values on `LoyaltyTierLadder`; this maps those to a translated
/// label and falls back to the raw value for anything the operator adds.
String tierLabel(BuildContext context, String tierName) {
  final l10n = context.l10n;
  return switch (tierName) {
    'Bronze' => l10n.loyalty_tierBronze,
    'Silver' => l10n.loyalty_tierSilver,
    'Gold' => l10n.loyalty_tierGold,
    'Platinum' => l10n.loyalty_tierPlatinum,
    _ => tierName,
  };
}

/// Localized display label for a reward's category, stored verbatim in
/// `loyalty_rewards.category`. Falls back to the raw value.
String rewardCategoryLabel(BuildContext context, String category) {
  final l10n = context.l10n;
  return switch (category) {
    'Discount' => l10n.loyalty_categoryDiscount,
    'FreeRide' => l10n.loyalty_categoryFreeRide,
    'Cashback' => l10n.loyalty_categoryCashback,
    'Package' => l10n.loyalty_categoryPackage,
    _ => category,
  };
}
