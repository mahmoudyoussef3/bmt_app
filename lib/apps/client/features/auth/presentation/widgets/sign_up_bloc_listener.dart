import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../routes/auth_routes.dart';

/// Reacts to sign-up results: on success it replaces the screen with the
/// "check your email" success screen, forwarding the entered [email]. Failures
/// render inline via [AuthErrorBanner] inside the form.
class SignUpBlocListener extends StatelessWidget {
  const SignUpBlocListener({
    super.key,
    required this.email,
    required this.child,
  });

  final String Function() email;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientAuthCubit, ClientAuthState>(
      listenWhen: (previous, current) =>
          previous.signUpStatus != current.signUpStatus,
      listener: (context, state) {
        if (state.signUpStatus == AuthSubmissionStatus.success) {
          Navigator.of(context).pushReplacementNamed(
            AuthRoutes.success,
            arguments: {'email': email()},
          );
        }
      },
      child: child,
    );
  }
}
