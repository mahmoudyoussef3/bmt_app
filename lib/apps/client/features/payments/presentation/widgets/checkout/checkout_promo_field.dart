import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_state.dart';

/// Promo entry, folded away until asked for.
///
/// Most riders have no code, and an open input next to the pay button reads as
/// one more thing to fill in — so it starts as a single line of text and only
/// becomes a field once tapped.
class CheckoutPromoField extends StatefulWidget {
  const CheckoutPromoField({
    super.key,
    required this.controller,
    required this.status,
    required this.code,
    required this.discount,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController controller;
  final PromoStatus status;
  final String? code;
  final int discount;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  State<CheckoutPromoField> createState() => _CheckoutPromoFieldState();
}

class _CheckoutPromoFieldState extends State<CheckoutPromoField> {
  bool _open = false;

  void _expand() {
    HapticFeedback.selectionClick();
    setState(() => _open = true);
  }

  void _clear() {
    widget.controller.clear();
    widget.onClear();
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    // A code in flight or a rejected one keeps the field open on its own: the
    // rider has to see what they typed to fix it, whatever [_open] last was.
    final open =
        _open ||
        widget.status == PromoStatus.checking ||
        widget.status == PromoStatus.invalid;

    return AnimatedSize(
      duration: ClientMotion.fast,
      curve: ClientMotion.curve,
      alignment: Alignment.topCenter,
      child: switch (widget.status) {
        PromoStatus.applied => _AppliedRow(
          code: widget.code ?? '',
          discount: widget.discount,
          onRemove: _clear,
        ),
        _ when open => _OpenRow(
          controller: widget.controller,
          checking: widget.status == PromoStatus.checking,
          invalid: widget.status == PromoStatus.invalid,
          onApply: widget.onApply,
        ),
        _ => _ClosedRow(onTap: _expand),
      },
    );
  }
}

class _ClosedRow extends StatelessWidget {
  const _ClosedRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ClientRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.local_offer_rounded, size: 16, color: primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Have a promo code?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(color: primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenRow extends StatelessWidget {
  const _OpenRow({
    required this.controller,
    required this.checking,
    required this.invalid,
    required this.onApply,
  });

  final TextEditingController controller;
  final bool checking;
  final bool invalid;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                enabled: !checking,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onApply(),
                style: ClientTypography.bodyMedium(context),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Enter code',
                  errorText: invalid ? 'That code is not valid' : null,
                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: checking ? null : onApply,
              child: checking
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AppliedRow extends StatelessWidget {
  const _AppliedRow({
    required this.code,
    required this.discount,
    required this.onRemove,
  });

  final String code;
  final int discount;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tone = ClientColors.journeyBadgeFor(
      context,
      ClientJourneyStatus.active,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(ClientRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: tone.label),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$code applied — you save $discount EGP',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelLarge(
                context,
              ).copyWith(color: tone.fg),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove promo code',
            icon: Icon(Icons.close_rounded, size: 16, color: tone.fg),
          ),
        ],
      ),
    );
  }
}
