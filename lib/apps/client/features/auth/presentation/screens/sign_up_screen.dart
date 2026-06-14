import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/widgets/app_dialogs.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_section_card.dart';
import '../widgets/premium_auth_button.dart';
import '../widgets/premium_auth_scaffold.dart';
import '../widgets/premium_auth_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    context.read<ClientAuthCubit>().signUp(
          fullName: _nameController.text.trim(),
          phone: _normalizeEgyptianPhone(_phoneController.text),
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
        );
  }

  String _normalizeEgyptianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '').trim();

    if (digits.startsWith('+20')) return digits;
    if (digits.startsWith('20')) return '+$digits';
    if (digits.startsWith('0')) return '+20${digits.substring(1)}';

    return '+20$digits';
  }

  void _goToSignIn() {
    Navigator.of(context).pushReplacementNamed(AuthRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: BlocListener<ClientAuthCubit, ClientAuthState>(
        listenWhen: (previous, current) =>
            previous.signUpStatus != current.signUpStatus,
        listener: (context, state) {
          if (state.signUpStatus == AuthSubmissionStatus.success) {
            Navigator.of(context).pushReplacementNamed(AuthRoutes.success);
            return;
          }

          if (state.signUpStatus == AuthSubmissionStatus.failure) {
            AppDialogs.showErrorDialog(
              context,
              title: 'Failed to create account',
              message: state.signUpError ?? l10n.auth_registrationFailed,
              onRetry: _submit,
            );
          }
        },
        child: PremiumAuthScaffold(
          logo: _AuthLogo(scheme: scheme),
          title: 'Create Account',
          subtitle:
              'Register your details once and enjoy booking trips, tracking buses, and managing subscriptions easily.',
          child: BlocBuilder<ClientAuthCubit, ClientAuthState>(
            buildWhen: (previous, current) =>
                previous.signUpStatus != current.signUpStatus,
            builder: (context, state) {
              final isLoading =
                  state.signUpStatus == AuthSubmissionStatus.loading;

              return AbsorbPointer(
                absorbing: isLoading,
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TrustBanner(scheme: scheme),
                        const SizedBox(height: 18),

                        AuthSectionCard(
                          title: 'Account Details',
                          icon: Icons.account_circle_outlined,
                          children: [
                            PremiumAuthTextField(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              labelText: l10n.auth_fullName,
                              prefixIcon: Icons.badge_outlined,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              onFieldSubmitted: (_) {
                                _phoneFocus.requestFocus();
                              },
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.length < 2) {
                                  return l10n.auth_invalidFullName;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            PremiumAuthTextField(
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              labelText: l10n.auth_phoneNumber,
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              onFieldSubmitted: (_) {
                                _emailFocus.requestFocus();
                              },
                              validator: (value) {
                                final digits = (value ?? '')
                                    .replaceAll(RegExp(r'[^0-9]'), '');
                                if (digits.length < 10) {
                                  return l10n.auth_invalidPhone;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        AuthSectionCard(
                          title: 'Login Details',
                          icon: Icons.lock_person_outlined,
                          children: [
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
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) {
                                final password = value ?? '';
                                if (password.length < 6) {
                                  return l10n.auth_invalidPassword;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        PremiumAuthButton(
                          text: isLoading
                              ? 'Creating Account...'
                              : l10n.auth_createAccount,
                          onPressed: isLoading ? null : _submit,
                          isLoading: isLoading,
                        ),

                        const SizedBox(height: 18),

                        _SignInLink(
                          scheme: scheme,
                          text: l10n.auth_alreadyHaveAccount,
                          actionText: l10n.auth_signIn,
                          onTap: isLoading ? null : _goToSignIn,
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
            errorBuilder: (_, __, ___) => Icon(
              Icons.directions_bus_rounded,
              color: scheme.primary,
            ),
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

class _TrustBanner extends StatelessWidget {
  const _TrustBanner({required this.scheme});

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
              Icons.verified_user_outlined,
              color: scheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your data is secure and used only to manage your trips and bookings.',
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

class _SignInLink extends StatelessWidget {
  const _SignInLink({
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
      'By clicking Create Account, a confirmation will be sent to your email.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            height: 1.55,
            color: scheme.onSurfaceVariant.withAlpha(190),
            fontWeight: FontWeight.w500,
          ),
    );
  }
}