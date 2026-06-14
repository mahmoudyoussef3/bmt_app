import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../routes/auth_routes.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../widgets/premium_auth_scaffold.dart';
import '../widgets/premium_auth_text_field.dart';
import '../widgets/premium_auth_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ClientAuthCubit>().signIn(
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
      listenWhen: (previous, current) => previous.signInStatus != current.signInStatus,
      listener: (context, state) {
        if (state.signInStatus == AuthSubmissionStatus.success) {
          Navigator.of(context).pushReplacementNamed(AuthRoutes.success);
        } else if (state.signInStatus == AuthSubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.signInError ?? AppLocalizations.of(context)!.auth_signInFailed),
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
        title: AppLocalizations.of(context)!.auth_welcomeBack,
        subtitle: AppLocalizations.of(context)!.auth_signInSubtitle,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email Field
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
              const SizedBox(height: 24),

              // Password Field
              PremiumAuthTextField(
                controller: _passwordController,
                labelText: AppLocalizations.of(context)!.auth_password,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return AppLocalizations.of(context)!.auth_required;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: Text(AppLocalizations.of(context)!.auth_forgotPassword),
                ),
              ),
              const SizedBox(height: 40),

              // Submit Button
              BlocBuilder<ClientAuthCubit, ClientAuthState>(
                builder: (context, state) {
                  final isLoading = state.signInStatus == AuthSubmissionStatus.loading;
                  return PremiumAuthButton(
                    text: AppLocalizations.of(context)!.auth_signIn,
                    onPressed: _submit,
                    isLoading: isLoading,
                  );
                },
              ),
              const SizedBox(height: 32),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.auth_noAccount,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(AuthRoutes.signUp);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    child: Text(AppLocalizations.of(context)!.auth_signUp),
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
