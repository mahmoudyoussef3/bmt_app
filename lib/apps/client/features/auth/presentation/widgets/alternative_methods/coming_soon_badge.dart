import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The "قريباً" pill on a sign-in method that exists but is not switched on
/// yet.
///
/// Tinted in the brand's own container blue rather than grey. Grey reads as
/// *broken* — the same colour a dead control gets — while a quiet brand tint
/// reads as *not yet*, which is the honest message: the method is real, the
/// provider is not connected. It is the only thing that changes between a live
/// provider button and a pending one, so the rider learns the vocabulary once.
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ClientColors.primaryContainerFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        context.l10n.auth_comingSoon,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: ClientTypography.labelSmall(context).copyWith(
          color: ClientColors.onPrimaryContainerFor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
