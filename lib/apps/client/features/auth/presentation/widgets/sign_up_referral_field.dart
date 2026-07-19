import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import 'auth_section_card.dart';
import 'premium_auth_text_field.dart';

/// The optional "referral code" section of the sign-up form.
class SignUpReferralField extends StatelessWidget {
  const SignUpReferralField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthSectionCard(
      title: l10n.auth_referralCodeSection,
      icon: Icons.card_giftcard_outlined,
      children: [
        PremiumAuthTextField(
          controller: controller,
          focusNode: focusNode,
          labelText: l10n.auth_referralCodeLabel,
          prefixIcon: Icons.confirmation_number_outlined,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.auth_referralCodeHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
