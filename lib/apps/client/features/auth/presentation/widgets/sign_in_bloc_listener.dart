import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Reacts to sign-in results: on success it resets the stack to the home shell.
/// Failures render inline via [AuthErrorBanner] inside the form, so nothing is
/// done here for them.
class SignInBlocListener extends StatelessWidget {
  const SignInBlocListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientAuthCubit, ClientAuthState>(
      listenWhen: (previous, current) =>
          previous.signInStatus != current.signInStatus,
      listener: (context, state) {
        if (state.signInStatus == AuthSubmissionStatus.success) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(ClientRoutes.home, (_) => false);
        }
      },
      child: child,
    );
  }
}
