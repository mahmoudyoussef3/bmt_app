import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

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
          const _Line(
            icon: Icons.lock_rounded,
            text: 'Card details are entered on the bank’s page, never stored '
                'by BMT.',
          ),
          const SizedBox(height: 10),
          const _Line(
            icon: Icons.event_seat_rounded,
            text: 'Your seat is held for you now and released only if the '
                'payment fails.',
          ),
          const SizedBox(height: 10),
          _Line(
            icon: Icons.support_agent_rounded,
            text: requiresReceipt
                ? 'Transfers are checked by our team, and you will be notified '
                      'once confirmed.'
                : 'Something looks wrong? Support can see this booking by its '
                      'reference.',
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
