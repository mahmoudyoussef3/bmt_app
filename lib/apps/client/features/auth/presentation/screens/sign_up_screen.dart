import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../routes/auth_routes.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../widgets/premium_auth_scaffold.dart';
import '../widgets/premium_auth_text_field.dart';
import '../widgets/premium_auth_button.dart';
import '../widgets/auth_section_card.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ClientAuthCubit>().signUp(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ClientAuthCubit, ClientAuthState>(
      listenWhen: (previous, current) => previous.signUpStatus != current.signUpStatus,
      listener: (context, state) {
        if (state.signUpStatus == AuthSubmissionStatus.success) {
          Navigator.of(context).pushReplacementNamed(AuthRoutes.success);
        } else if (state.signUpStatus == AuthSubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.signUpError ?? AppLocalizations.of(context)!.auth_registrationFailed),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: PremiumAuthScaffold(
        logo: Row(
          children: [
            Image.asset(
              'assets/images/app_icon.png',
              width: 42,
              height: 42,
            ),
            const SizedBox(width: 12),
            Text(
              'EasyWay',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.primaryColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        title: AppLocalizations.of(context)!.auth_createAccountTitle,
        subtitle: AppLocalizations.of(context)!.auth_signUpSubtitle,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthSectionCard(
                title: AppLocalizations.of(context)!.auth_fullName,
                icon: Icons.person_outline,
                children: [
                  PremiumAuthTextField(
                    controller: _nameController,
                    labelText: AppLocalizations.of(context)!.auth_fullName,
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.trim().length < 2) return AppLocalizations.of(context)!.auth_invalidFullName;
                      return null;
                    },
                  ),
                ],
              ),

              AuthSectionCard(
                title: AppLocalizations.of(context)!.auth_phoneNumber,
                icon: Icons.contact_phone_outlined,
                children: [
                  PremiumAuthTextField(
                    controller: _phoneController,
                    labelText: AppLocalizations.of(context)!.auth_phoneNumber,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().length < 8) return AppLocalizations.of(context)!.auth_invalidPhone;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PremiumAuthTextField(
                    controller: _emailController,
                    labelText: AppLocalizations.of(context)!.auth_email,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return AppLocalizations.of(context)!.auth_required;
                      if (!value.contains('@')) return AppLocalizations.of(context)!.auth_invalidEmail;
                      return null;
                    },
                  ),
                ],
              ),

              AuthSectionCard(
                title: AppLocalizations.of(context)!.auth_password,
                icon: Icons.security_outlined,
                children: [
                  PremiumAuthTextField(
                    controller: _passwordController,
                    labelText: AppLocalizations.of(context)!.auth_password,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.length < 6) return AppLocalizations.of(context)!.auth_invalidPassword;
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Submit Button
              BlocBuilder<ClientAuthCubit, ClientAuthState>(
                builder: (context, state) {
                  final isLoading = state.signUpStatus == AuthSubmissionStatus.loading;
                  return PremiumAuthButton(
                    text: AppLocalizations.of(context)!.auth_createAccount,
                    onPressed: _submit,
                    isLoading: isLoading,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.auth_alreadyHaveAccount,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(AuthRoutes.signIn);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    child: Text(AppLocalizations.of(context)!.auth_signIn),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
