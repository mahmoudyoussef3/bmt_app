import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

/// The gradient capsule that tracks the selected tab in the nav island, lifted
/// off the bar by a primary-tinted glow.
///
/// It is positioned (and animated) by `ClientBottomNavigation` — it owns only
/// its own paint, never its placement.
class ClientNavSelectionPill extends StatelessWidget {
  const ClientNavSelectionPill({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: ClientColors.primaryGradientFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primaryFor(context).withAlpha(70),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }
}
