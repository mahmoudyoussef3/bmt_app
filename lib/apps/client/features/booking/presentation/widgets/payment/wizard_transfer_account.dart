import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';

/// Where to send the money.
///
/// The account number is the one thing the rider must reproduce exactly, so it
/// is copyable rather than re-typed — a mistyped digit is a transfer we cannot
/// match back to their booking.
class WizardTransferAccount extends StatelessWidget {
  const WizardTransferAccount({super.key, required this.method});

  final PaymentMethodData method;

  @override
  Widget build(BuildContext context) {
    final account = method.transferAccount?.trim() ?? '';
    final holder = method.accountHolder?.trim() ?? '';
    final instructions = method.instructions?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send ${method.title} to',
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
          const SizedBox(height: 6),
          if (account.isEmpty)
            Text(
              'Contact support for the transfer details.',
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            )
          else
            _CopyableAccount(account: account),
          if (holder.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              holder,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ],
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              instructions,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyableAccount extends StatelessWidget {
  const _CopyableAccount({required this.account});

  final String account;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SelectableText(
            account,
            style: ClientTypography.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w800,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Copy account',
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.copy_rounded,
            size: 18,
            color: ClientColors.primaryFor(context),
          ),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: account));
            await HapticFeedback.selectionClick();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account number copied.')),
            );
          },
        ),
      ],
    );
  }
}
