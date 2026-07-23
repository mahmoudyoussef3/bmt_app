import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'auth_section_card.dart';
import 'auth_text_field.dart';

/// The optional "referral code" section of the sign-up form. It keeps its own
/// card so the required fields above never look like they need it too.
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
        AuthTextField(
          controller: controller,
          focusNode: focusNode,
          label: l10n.auth_referralCodeLabel,
          icon: Icons.confirmation_number_outlined,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: ClientSpacing.sm),
        Text(
          l10n.auth_referralCodeHint,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
      ],
    );
  }
}
