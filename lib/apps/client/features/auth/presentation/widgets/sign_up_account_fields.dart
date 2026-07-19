import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import 'auth_section_card.dart';
import 'auth_validators.dart';
import 'premium_auth_text_field.dart';

/// The "account details" section of the sign-up form: full name + phone.
class SignUpAccountFields extends StatelessWidget {
  const SignUpAccountFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.nameFocus,
    required this.phoneFocus,
    required this.onPhoneSubmitted,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final FocusNode nameFocus;
  final FocusNode phoneFocus;
  final VoidCallback onPhoneSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthSectionCard(
      title: l10n.auth_accountDetails,
      icon: Icons.account_circle_outlined,
      children: [
        PremiumAuthTextField(
          controller: nameController,
          focusNode: nameFocus,
          labelText: l10n.auth_fullName,
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onFieldSubmitted: (_) => phoneFocus.requestFocus(),
          validator: (value) => AuthValidators.fullName(value, l10n),
        ),
        const SizedBox(height: 14),
        PremiumAuthTextField(
          controller: phoneController,
          focusNode: phoneFocus,
          labelText: l10n.auth_phoneNumber,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          onFieldSubmitted: (_) => onPhoneSubmitted(),
          validator: (value) => AuthValidators.phone(value, l10n),
        ),
      ],
    );
  }
}
