import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
/*
/// The three things a rider worries about at the moment of paying, answered
/// before they ask. Concrete promises about how this checkout behaves — not
/// decorative "secure payment" badges.
class CheckoutAssurance extends StatelessWidget {
  const CheckoutAssurance({super.key, required this.requiresReceipt});

  /// Transfer methods are reviewed by an operator, so the promise is about how
  /// fast that happens — not about an instant charge.
  final bool requiresReceipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          _Line(
            icon: Icons.lock_rounded,
            text: context.l10n.payments_assuranceCardDetails,
          ),
          const SizedBox(height: 10),
          _Line(
            icon: Icons.event_seat_rounded,
            text: context.l10n.payments_assuranceSeatHeld,
          ),
          const SizedBox(height: 10),
          _Line(
            icon: Icons.support_agent_rounded,
            text: requiresReceipt
                ? context.l10n.payments_assuranceTransferChecked
                : context.l10n.payments_assuranceSupportReference,
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: ClientColors.textTertiaryFor(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
      ],
    );
  }


}
*/