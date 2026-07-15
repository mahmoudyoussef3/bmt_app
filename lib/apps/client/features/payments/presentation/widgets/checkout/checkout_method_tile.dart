import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// One way to pay.
///
/// The tile only spells out what pressing pay will *do* — redirect, ask for a
/// receipt, deduct a balance — once it is the chosen one. Printing that on
/// every tile at once is how a payment list turns into a wall of text.
class CheckoutMethodTile extends StatelessWidget {
  const CheckoutMethodTile({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
    this.note,
    this.warning,
  });

  final PaymentMethodData method;
  final bool selected;
  final VoidCallback onTap;

  /// Standing fact about the method — a wallet balance, for instance.
  final String? note;

  /// Why this method cannot cover the fare right now.
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: ClientMotion.fast,
        curve: ClientMotion.curve,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? ClientColors.primaryContainerFor(context)
              : ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.md),
          border: Border.all(
            color: selected ? primary : ClientColors.borderFor(context),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _MethodIcon(type: method.type, selected: selected),
                const SizedBox(width: 12),
                Expanded(child: _Titles(method: method, note: note)),
                const SizedBox(width: 8),
                _Radio(selected: selected),
              ],
            ),
            if (selected || warning != null)
              _Detail(
                text: warning ?? _nextStep(context, method.type),
                isWarning: warning != null,
              ),
          ],
        ),
      ),
    );
  }

  String _nextStep(BuildContext context, PaymentMethodType type) =>
      switch (type) {
        PaymentMethodType.creditCard => context.l10n.payments_nextStepCard,
        PaymentMethodType.instapay => context.l10n.payments_nextStepInstapay,
        PaymentMethodType.bankTransfer =>
          context.l10n.payments_nextStepBankTransfer,
        PaymentMethodType.vodafoneCash =>
          context.l10n.payments_nextStepVodafoneCash,
        PaymentMethodType.walletBalance =>
          context.l10n.payments_nextStepWallet,
      };
}

class _Titles extends StatelessWidget {
  const _Titles({required this.method, required this.note});

  final PaymentMethodData method;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                method.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (method.recommended) ...[
              const SizedBox(width: 6),
              const _RecommendedBadge(),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          note ?? method.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.bodySmall(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
            fontWeight: note == null ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    final tone = ClientColors.journeyBadgeFor(
      context,
      ClientJourneyStatus.active,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        context.l10n.payments_fastestBadge,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: tone.fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MethodIcon extends StatelessWidget {
  const _MethodIcon({required this.type, required this.selected});

  final PaymentMethodType type;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return AnimatedContainer(
      duration: ClientMotion.fast,
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? primary : ClientColors.surfaceMutedFor(context),
      ),
      child: Icon(
        switch (type) {
          PaymentMethodType.creditCard => Icons.credit_card_rounded,
          PaymentMethodType.instapay => Icons.swap_horiz_rounded,
          PaymentMethodType.bankTransfer => Icons.account_balance_rounded,
          PaymentMethodType.vodafoneCash => Icons.send_to_mobile_rounded,
          PaymentMethodType.walletBalance =>
            Icons.account_balance_wallet_rounded,
        },
        size: 20,
        color: selected
            ? ClientColors.textInverse
            : ClientColors.textSecondaryFor(context),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return AnimatedContainer(
      duration: ClientMotion.fast,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? primary : Colors.transparent,
        border: Border.all(
          color: selected ? primary : ClientColors.borderStrongFor(context),
          width: 1.6,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: ClientColors.textInverse,
            )
          : null,
    );
  }
}

/// The line under a chosen method: what happens next, or why it will not work.
class _Detail extends StatelessWidget {
  const _Detail({required this.text, required this.isWarning});

  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? ClientColors.journeyRed
        : ClientColors.textSecondaryFor(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12, start: 54),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isWarning
              ? Icon(Icons.error_outline_rounded, size: 14, color: color)
              : DirectionalIcon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: color,
                ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: ClientTypography.bodySmall(context).copyWith(
                color: color,
                fontWeight: isWarning ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
