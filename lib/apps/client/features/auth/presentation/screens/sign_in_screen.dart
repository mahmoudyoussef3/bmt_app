import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_brand_logo.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/premium_auth_button.dart';
import '../widgets/premium_auth_scaffold.dart';
import '../widgets/premium_auth_text_field.dart';
import '../widgets/remember_me_checkbox.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _prefillRememberedCredentials();
  }

  Future<void> _prefillRememberedCredentials() async {
    final creds = await context
        .read<ClientAuthCubit>()
        .loadRememberedCredentials();
    if (!mounted || creds == null) return;
    setState(() {
      _emailController.text = creds.email;
      _passwordController.text = creds.password;
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    context.read<ClientAuthCubit>().signIn(
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
  }

  void _goToForgotPassword() {
    Navigator.of(context).pushNamed(AuthRoutes.forgotPassword);
  }

  void _goToSignUp() {
    Navigator.of(context).pushReplacementNamed(AuthRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<ClientAuthCubit, ClientAuthState>(
        listenWhen: (previous, current) =>
            previous.signInStatus != current.signInStatus,
        listener: (context, state) {
          if (state.signInStatus == AuthSubmissionStatus.success) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (_) => false);
          }
          // Failures render inline via [AuthErrorBanner] below.
        },
        child: PremiumAuthScaffold(
          logo: const AuthBrandLogo(),
          title: l10n.auth_welcomeBack,
          subtitle: l10n.auth_signInHeroSubtitle,
          child: BlocBuilder<ClientAuthCubit, ClientAuthState>(
            buildWhen: (previous, current) =>
                previous.signInStatus != current.signInStatus,
            builder: (context, state) {
              final isLoading =
                  state.signInStatus == AuthSubmissionStatus.loading;

              return AbsorbPointer(
                absorbing: isLoading,
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthErrorBanner(
                          message:
                              state.signInStatus ==
                                  AuthSubmissionStatus.failure
                              ? (state.signInError ?? l10n.auth_signInFailed)
                              : null,
                          onDismiss: context
                              .read<ClientAuthCubit>()
                              .dismissSignInError,
                        ),
                        _WelcomeBackCard(scheme: scheme),
                        const SizedBox(height: 18),

                        PremiumAuthTextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          labelText: l10n.auth_email,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) {
                            _passwordFocus.requestFocus();
                          },
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return l10n.auth_required;

                            final validEmail = RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(email);

                            if (!validEmail) {
                              return l10n.auth_invalidEmail;
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        PremiumAuthTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          labelText: l10n.auth_password,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) {
                              return l10n.auth_required;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 4),

                        RememberMeCheckbox(
                          value: _rememberMe,
                          label: l10n.auth_rememberMe,
                          onChanged: isLoading
                              ? (_) {}
                              : (checked) =>
                                    setState(() => _rememberMe = checked),
                        ),

                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: isLoading ? null : _goToForgotPassword,
                            icon: const Icon(
                              Icons.help_outline_rounded,
                              size: 18,
                            ),
                            label: Text(l10n.auth_forgotPassword),
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        PremiumAuthButton(
                          text: isLoading
                              ? l10n.auth_signingIn
                              : l10n.auth_signIn,
                          onPressed: isLoading ? null : _submit,
                          isLoading: isLoading,
                        ),

                        const SizedBox(height: 18),

                        _CreateAccountLink(
                          scheme: scheme,
                          text: l10n.auth_noAccount,
                          actionText: l10n.auth_signUp,
                          onTap: isLoading ? null : _goToSignUp,
                        ),

                        const SizedBox(height: 8),

                        _SecurityNote(scheme: scheme),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    );
  }
}

class _WelcomeBackCard extends StatelessWidget {
  const _WelcomeBackCard({required this.scheme});

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
            child: Icon(Icons.route_rounded, color: scheme.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.auth_signInInfoCard,
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

class _CreateAccountLink extends StatelessWidget {
  const _CreateAccountLink({
    required this.scheme,
    required this.text,
    required this.actionText,
    required this.onTap,
  });

  final ColorScheme scheme;
  final String text;
  final String actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.auth_signInSecurityNote,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        height: 1.55,
        color: scheme.onSurfaceVariant.withAlpha(190),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
