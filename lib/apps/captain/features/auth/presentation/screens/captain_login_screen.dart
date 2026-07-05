import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../cubit/captain_auth_cubit.dart';
import '../widgets/captain_auth_error_banner.dart';
import '../widgets/captain_auth_field.dart';
import '../widgets/captain_auth_header.dart';
import '../widgets/captain_auth_scaffold.dart';
import 'captain_request_access_screen.dart';

class CaptainLoginScreen extends StatefulWidget {
  const CaptainLoginScreen({super.key});

  @override
  State<CaptainLoginScreen> createState() => _CaptainLoginScreenState();
}

class _CaptainLoginScreenState extends State<CaptainLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CaptainAuthCubit>().signIn(
      email: _emailCtrl.text.trim().toLowerCase(),
      password: _passwordCtrl.text,
    );
  }

  void _openRequestAccess() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CaptainRequestAccessScreen()),
    );
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact operations to reset your captain password.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CaptainAuthCubit>();

    return BlocBuilder<CaptainAuthCubit, CaptainAuthState>(
      builder: (context, state) {
        final loading = state is CaptainAuthLoading;
        final error = state is CaptainAuthError ? state.message : null;

        return AbsorbPointer(
          absorbing: loading,
          child: CaptainAuthScaffold(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CaptainAuthHeader(
                      title: 'Captain Sign In',
                      subtitle: 'Sign in to see your trips and start driving.',
                    ),
                    const SizedBox(height: 40),
                    CaptainAuthErrorBanner(
                      message: error,
                      onDismiss: cubit.resetError,
                    ),
                    CaptainAuthField(
                      controller: _emailCtrl,
                      label: 'Email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)
                            ? null
                            : 'Enter a valid email address';
                      },
                    ),
                    const SizedBox(height: 14),
                    CaptainAuthField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Enter your password' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading ? null : _forgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CaptainButton(
                      label: loading ? 'Signing in...' : 'Sign In',
                      isLoading: loading,
                      onPressed: loading ? null : _submit,
                    ),
                    const SizedBox(height: 20),
                    _RequestAccessLink(
                      onTap: loading ? null : _openRequestAccess,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RequestAccessLink extends StatelessWidget {
  const _RequestAccessLink({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'New to the fleet?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'Request access',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
