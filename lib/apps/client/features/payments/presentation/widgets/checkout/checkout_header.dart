import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Checkout's top bar. A payment screen has to answer two questions before the
/// rider will read anything else: how do I get out of here, and is my money
/// safe — so the exit and the encryption badge sit at the two ends of the row.
class CheckoutHeader extends StatelessWidget {
  const CheckoutHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: DirectionalIcon(
              Icons.arrow_back_rounded,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.payments_checkoutTitle,
              style: ClientTypography.headingMedium(
                context,
              ).copyWith(color: ClientColors.textPrimaryFor(context)),
            ),
          ),
          const _EncryptedChip(),
        ],
      ),
    );
  }
}

class _EncryptedChip extends StatelessWidget {
  const _EncryptedChip();

  @override
  Widget build(BuildContext context) {
    final tone = ClientColors.journeyBadgeFor(
      context,
      ClientJourneyStatus.active,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 13, color: tone.label),
          const SizedBox(width: 5),
          Text(
            context.l10n.payments_encrypted,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: tone.fg),
          ),
        ],
      ),
    );
  }
}
