import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/validation/contact_validation.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'sign_up_bloc_listener.dart';
import 'sign_up_body.dart';

/// The interactive sign-up form. Owns the five field controllers (the one place
/// they can be disposed) and the form key; layout lives in [SignUpBody].
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim().toLowerCase();

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final referral = _referralController.text.trim();
    context.read<ClientAuthCubit>().signUp(
      fullName: _nameController.text.trim(),
      phone: ContactValidation.normalizeEgyptianPhone(_phoneController.text),
      email: _email,
      password: _passwordController.text,
      referralCode: referral.isEmpty ? null : referral.toUpperCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SignUpBlocListener(
      email: () => _email,
      child: BlocBuilder<ClientAuthCubit, ClientAuthState>(
        buildWhen: (previous, current) =>
            previous.signUpStatus != current.signUpStatus,
        builder: (context, state) {
          final isLoading = state.signUpStatus == AuthSubmissionStatus.loading;
          final error = state.signUpStatus == AuthSubmissionStatus.failure
              ? (state.signUpError ?? l10n.auth_registrationFailed)
              : null;
          return SignUpBody(
            formKey: _formKey,
            isLoading: isLoading,
            error: error,
            onDismissError: context.read<ClientAuthCubit>().dismissSignUpError,
            onSubmit: _submit,
            nameController: _nameController,
            phoneController: _phoneController,
            emailController: _emailController,
            passwordController: _passwordController,
            referralController: _referralController,
          );
        },
      ),
    );
  }
}
