import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';

import '../cubit/captain_activation_cubit.dart';
import 'captain_welcome_home_screen.dart';

/// Wires [CaptainWelcomeHomeScreen] to the activation cubit that turns the
/// local session into an operational one.
class CaptainWelcomeHome extends StatelessWidget {
  const CaptainWelcomeHome({
    super.key,
    required this.session,
    required this.onSignOut,
  });

  final CaptainLocalSession session;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => captainGetIt<CaptainActivationCubit>(),
      child: CaptainWelcomeHomeScreen(session: session, onSignOut: onSignOut),
    );
  }
}
