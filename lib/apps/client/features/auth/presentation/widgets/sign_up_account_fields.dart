import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'auth_text_field.dart';
import 'auth_validators.dart';

/// Who the rider is: full name + phone.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: nameController,
          focusNode: nameFocus,
          label: l10n.auth_fullName,
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onFieldSubmitted: (_) => phoneFocus.requestFocus(),
          validator: (value) => AuthValidators.fullName(value, l10n),
        ),
        const SizedBox(height: ClientSpacing.sm),
        AuthTextField(
          controller: phoneController,
          focusNode: phoneFocus,
          label: l10n.auth_phoneNumber,
          icon: Icons.phone_outlined,
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
