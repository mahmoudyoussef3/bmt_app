import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'auth_form_header.dart';
import 'sign_in_actions.dart';
import 'sign_in_fields.dart';

/// The interactive sign-in form. Owns the form controllers (the one place they
/// can be disposed) and prefills remembered credentials; everything visual is a
/// stateless child widget.
class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ClientAuthCubit>().signIn(
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ClientAuthCubit, ClientAuthState>(
      buildWhen: (previous, current) =>
          previous.signInStatus != current.signInStatus,
      builder: (context, state) {
        final isLoading = state.signInStatus == AuthSubmissionStatus.loading;
        final error = state.signInStatus == AuthSubmissionStatus.failure
            ? (state.signInError ?? l10n.auth_signInFailed)
            : null;
        return AbsorbPointer(
          absorbing: isLoading,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthFormHeader(
                    error: error,
                    onDismissError: context
                        .read<ClientAuthCubit>()
                        .dismissSignInError,
                    infoIcon: Icons.route_rounded,
                    infoText: l10n.auth_signInInfoCard,
                  ),
                  SignInFields(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    emailFocus: _emailFocus,
                    passwordFocus: _passwordFocus,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 4),
                  SignInActions(
                    isLoading: isLoading,
                    rememberMe: _rememberMe,
                    onRememberChanged: (checked) =>
                        setState(() => _rememberMe = checked),
                    onSubmit: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
