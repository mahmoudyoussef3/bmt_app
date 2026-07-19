import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Icon and accent color for an operator-defined reward category.
///
/// Every category gets a distinct accent — the categories previously shared
/// colors, which made two different reward types read as the same thing.
abstract final class RewardCategoryVisuals {
  const RewardCategoryVisuals._();

  static IconData iconFor(String category) => switch (category) {
    'Discount' => Icons.local_offer_rounded,
    'FreeRide' => Icons.confirmation_number_rounded,
    'Cashback' => Icons.monetization_on_rounded,
    'Package' => Icons.subscriptions_rounded,
    _ => Icons.stars_rounded,
  };

  static Color colorFor(BuildContext context, String category) =>
      switch (category) {
        'Discount' => ClientColors.primaryFor(context),
        'FreeRide' => ClientColors.journeyCyan,
        'Cashback' => ClientColors.journeyAmber,
        'Package' => ClientColors.journeyPurple,
        _ => ClientColors.journeySlate,
      };
}
