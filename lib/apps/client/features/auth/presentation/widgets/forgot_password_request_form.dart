import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_state.dart';
import 'auth_info_card.dart';
import 'auth_section_card.dart';
import 'auth_security_note.dart';
import 'auth_text_field.dart';
import 'auth_validators.dart';

/// The "enter your email" request form. Owns the email controller; loading and
/// errors come from [ForgotPasswordCubit].
class ForgotPasswordRequestForm extends StatefulWidget {
  const ForgotPasswordRequestForm({super.key});

  @override
  State<ForgotPasswordRequestForm> createState() =>
      _ForgotPasswordRequestFormState();
}

class _ForgotPasswordRequestFormState extends State<ForgotPasswordRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<ForgotPasswordCubit>();
    cubit.emailChanged(_emailController.text.trim().toLowerCase());
    cubit.submitEmail();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        final isLoading = state.status == ForgotPasswordStatus.loading;
        return AbsorbPointer(
          absorbing: isLoading,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthSectionCard(
                    children: [
                      AuthTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        label: l10n.auth_email,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (value) => context
                            .read<ForgotPasswordCubit>()
                            .emailChanged(value.trim().toLowerCase()),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) => AuthValidators.email(value, l10n),
                      ),
                      const SizedBox(height: ClientSpacing.sm),
                      AuthInfoCard(
                        icon: Icons.lock_reset_rounded,
                        text: l10n.auth_resetInfoCard,
                      ),
                    ],
                  ),
                  const SizedBox(height: ClientSpacing.lg),
                  ClientButton(
                    label: isLoading
                        ? l10n.auth_sendingLink
                        : l10n.auth_sendResetLink,
                    onPressed: isLoading ? null : _submit,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: ClientSpacing.xs),
                  Center(
                    child: ClientButton.text(
                      label: l10n.auth_backToLogin,
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: ClientSpacing.xs),
                  AuthSecurityNote(text: l10n.auth_forgotSecurityNote),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
