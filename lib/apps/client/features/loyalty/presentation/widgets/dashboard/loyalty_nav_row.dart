import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../cubit/loyalty_cubit.dart';
import '../../cubit/loyalty_state.dart';
import 'loyalty_nav_card.dart';

/// The pair of tiles leading to the catalog and the ledger.
class LoyaltyNavRow extends StatelessWidget {
  const LoyaltyNavRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LoyaltyCubit>();

    // IntrinsicHeight gives the two cards a common height even when their
    // subtitles wrap differently. `CrossAxisAlignment.stretch` alone cannot:
    // inside the dashboard's ListView the row is vertically unbounded, so
    // stretching asks for an infinite height and the layout asserts.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LoyaltyNavCard(
              icon: Icons.wallet_giftcard_rounded,
              title: l10n.loyalty_navRedeemTitle,
              subtitle: l10n.loyalty_navRedeemSubtitle,
              color: ClientColors.journeyAmber,
              onTap: () => cubit.showView(LoyaltyView.rewards),
            ),
          ),
          const SizedBox(width: ClientSpacing.xs),
          Expanded(
            child: LoyaltyNavCard(
              icon: Icons.receipt_long_rounded,
              title: l10n.loyalty_navHistoryTitle,
              subtitle: l10n.loyalty_navHistorySubtitle,
              color: ClientColors.journeyCyan,
              onTap: () => cubit.showView(LoyaltyView.history),
            ),
          ),
        ],
      ),
    );
  }
}
