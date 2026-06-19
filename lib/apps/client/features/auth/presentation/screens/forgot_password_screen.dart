import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/widgets/app_dialogs.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_state.dart';
import '../widgets/premium_auth_button.dart';
import '../widgets/premium_auth_scaffold.dart';
import '../widgets/premium_auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    context.read<ForgotPasswordCubit>().emailChanged(
      _emailController.text.trim().toLowerCase(),
    );

    context.read<ForgotPasswordCubit>().submitEmail();
  }

  void _goBackToLogin() {
    Navigator.of(context).pop();
  }

  String _localizedError(BuildContext context, String? error) {
    final l10n = AppLocalizations.of(context)!;

    if (error == 'RateLimit') {
      return l10n.auth_rateLimited;
    }

    if (error == null || error.trim().isEmpty) {
      return l10n.auth_unknownError;
    }

    return error;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == ForgotPasswordStatus.failure) {
            AppDialogs.showErrorDialog(
              context,
              title: 'Failed to send recovery link',
              message: _localizedError(context, state.errorMessage),
              onRetry: _submit,
            );
          }
        },
        builder: (context, state) {
          if (state.status == ForgotPasswordStatus.success) {
            return _ForgotPasswordSuccessView(
              state: state,
              scheme: scheme,
              onBackToLogin: _goBackToLogin,
              onResend: _submit,
            );
          }

          final isLoading = state.status == ForgotPasswordStatus.loading;

          return PremiumAuthScaffold(
            logo: _AuthLogo(scheme: scheme),
            title: 'Forgot Password?',
            subtitle:
                'Do not worry, enter your email and we will send you a secure link to reset your password.',
            child: AbsorbPointer(
              absorbing: isLoading,
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ResetInfoCard(scheme: scheme),
                      const SizedBox(height: 18),

                      PremiumAuthTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        labelText: l10n.auth_email,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (value) {
                          context.read<ForgotPasswordCubit>().emailChanged(
                            value.trim().toLowerCase(),
                          );
                        },
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return l10n.auth_required;
                          }

                          final validEmail = RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(email);

                          if (!validEmail) {
                            return l10n.auth_invalidEmail;
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      PremiumAuthButton(
                        text: isLoading
                            ? 'Sending link...'
                            : l10n.auth_sendResetLink,
                        onPressed: isLoading ? null : _submit,
                        isLoading: isLoading,
                      ),

                      const SizedBox(height: 16),

                      TextButton.icon(
                        onPressed: isLoading ? null : _goBackToLogin,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(l10n.auth_backToLogin),
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      _SecurityNote(scheme: scheme),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ForgotPasswordSuccessView extends StatelessWidget {
  const _ForgotPasswordSuccessView({
    required this.state,
    required this.scheme,
    required this.onBackToLogin,
    required this.onResend,
  });

  final ForgotPasswordState state;
  final ColorScheme scheme;
  final VoidCallback onBackToLogin;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canResend = state.cooldownRemaining == 0;

    return PremiumAuthScaffold(
      logo: _AuthLogo(scheme: scheme),
      title: 'Check your email',
      subtitle: l10n.auth_checkEmailMessage(state.email),
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SuccessMailCard(scheme: scheme, email: state.email),
          const SizedBox(height: 24),
          PremiumAuthButton(
            text: l10n.auth_backToLogin,
            onPressed: onBackToLogin,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: canResend ? onResend : null,
            icon: Icon(
              canResend
                  ? Icons.refresh_rounded
                  : Icons.hourglass_bottom_rounded,
              size: 18,
            ),
            label: Text(
              canResend
                  ? l10n.auth_resendLink
                  : l10n.auth_resendIn(state.cooldownRemaining),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _EmailHelpCard(scheme: scheme),
        ],
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withAlpha(45)),
          ),
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                Icon(Icons.directions_bus_rounded, color: scheme.primary),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'EasyWay',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: scheme.primary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _ResetInfoCard extends StatelessWidget {
  const _ResetInfoCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withAlpha(38)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'We will send a temporary link to your email. Open it soon to set a new password.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.55,
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessMailCard extends StatelessWidget {
  const _SuccessMailCard({required this.scheme, required this.email});

  final ColorScheme scheme;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withAlpha(42)),
      ),
      child: Column(
        children: [
          Container(
            height: 86,
            width: 86,
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 42,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Recovery link sent',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open the email and click the link to reset your password.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.55,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailHelpCard extends StatelessWidget {
  const _EmailHelpCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: scheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Did not find the email? Check your spam folder or wait a bit before resending.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.55,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      'For your security, the system may prevent sending multiple links in a short period.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        height: 1.55,
        color: scheme.onSurfaceVariant.withAlpha(190),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
