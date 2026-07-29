import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../cubit/reset_password_cubit.dart';
import '../cubit/reset_password_state.dart';
import 'auth_section_card.dart';
import 'auth_text_field.dart';
import 'auth_validators.dart';
import 'password_strength_meter.dart';

/// The "choose a new password" form. Owns its two controllers; loading and
/// errors come from [ResetPasswordCubit].
class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? value, AppLocalizations l10n) {
    if ((value ?? '').isEmpty) return l10n.auth_required;
    if (value != _passwordController.text) {
      return l10n.auth_passwordsDoNotMatch;
    }
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ResetPasswordCubit>().submit(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        final isLoading = state.status == ResetPasswordStatus.loading;
        return AbsorbPointer(
          absorbing: isLoading,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthSectionCard(
                  children: [
                    AuthTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      label: l10n.auth_newPassword,
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                      validator: (value) => AuthValidators.password(
                        value,
                        l10n,
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _passwordController,
                      builder: (context, value, _) =>
                          PasswordStrengthMeter(password: value.text),
                    ),
                    const SizedBox(height: ClientSpacing.sm),
                    AuthTextField(
                      controller: _confirmController,
                      focusNode: _confirmFocus,
                      label: l10n.auth_confirmPassword,
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => _confirmValidator(value, l10n),
                    ),
                  ],
                ),
                const SizedBox(height: ClientSpacing.lg),
                ClientButton(
                  label: isLoading
                      ? l10n.auth_updatingPassword
                      : l10n.auth_updatePassword,
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
