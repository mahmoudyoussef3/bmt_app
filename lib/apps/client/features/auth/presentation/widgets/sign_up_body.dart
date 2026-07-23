import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'auth_error_banner.dart';
import 'auth_info_card.dart';
import 'auth_section_card.dart';
import 'sign_up_account_fields.dart';
import 'sign_up_actions.dart';
import 'sign_up_credentials_fields.dart';
import 'sign_up_referral_field.dart';

/// Lays out the sign-up fields and actions. Owns the field focus nodes (used
/// only to advance focus between inputs); the controllers and form key are
/// owned by [SignUpForm].
///
/// The four required inputs sit in one card rather than the two titled cards
/// they used to be split across: "account details" and "login details" were
/// separate headers over what the rider experiences as a single act of signing
/// up, and each header cost more height than the fields under it.
class SignUpBody extends StatefulWidget {
  const SignUpBody({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.error,
    required this.onDismissError,
    required this.onSubmit,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.referralController,
  });

  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String? error;
  final VoidCallback onDismissError;
  final VoidCallback onSubmit;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController referralController;

  @override
  State<SignUpBody> createState() => _SignUpBodyState();
}

class _SignUpBodyState extends State<SignUpBody> {
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _referralFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _referralFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AbsorbPointer(
      absorbing: widget.isLoading,
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthErrorBanner(
                message: widget.error,
                onDismiss: widget.onDismissError,
              ),
              AuthSectionCard(
                title: l10n.auth_accountDetails,
                icon: Icons.account_circle_outlined,
                children: [
                  SignUpAccountFields(
                    nameController: widget.nameController,
                    phoneController: widget.phoneController,
                    nameFocus: _nameFocus,
                    phoneFocus: _phoneFocus,
                    onPhoneSubmitted: _emailFocus.requestFocus,
                  ),
                  const SizedBox(height: ClientSpacing.sm),
                  SignUpCredentialsFields(
                    emailController: widget.emailController,
                    passwordController: widget.passwordController,
                    emailFocus: _emailFocus,
                    passwordFocus: _passwordFocus,
                    onPasswordSubmitted: _referralFocus.requestFocus,
                  ),
                ],
              ),
              const SizedBox(height: ClientSpacing.md),
              SignUpReferralField(
                controller: widget.referralController,
                focusNode: _referralFocus,
                onSubmit: widget.onSubmit,
              ),
              const SizedBox(height: ClientSpacing.md),
              AuthInfoCard(
                icon: Icons.verified_user_outlined,
                text: l10n.auth_signUpTrustBanner,
              ),
              const SizedBox(height: ClientSpacing.lg),
              SignUpActions(
                isLoading: widget.isLoading,
                onSubmit: widget.onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
