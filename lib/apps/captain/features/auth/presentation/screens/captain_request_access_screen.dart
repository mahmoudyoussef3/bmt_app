import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';

import '../../../onboarding/presentation/cubit/captain_onboarding_cubit.dart';
import '../../../onboarding/presentation/screens/captain_onboarding_flow.dart';
import '../../../onboarding/presentation/screens/captain_welcome_home.dart';

/// Captain "sign up" — a self-service access request reviewed by operations.
///
/// Drivers are provisioned by the Dashboard (the operational source of truth),
/// so this submits an application (name + phone) rather than minting a live
/// account. Hosts the real onboarding flow; used when reached as a pushed
/// route (the auth gate hosts the same flow inline).
class CaptainRequestAccessScreen extends StatelessWidget {
  const CaptainRequestAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => captainGetIt<CaptainOnboardingCubit>()..init(null),
      child: CaptainOnboardingFlow(
        onBackToLogin: () => Navigator.of(context).maybePop(),
        onEnterHome: (CaptainLocalSession session) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CaptainWelcomeHome(
                session: session,
                onSignOut: () async {
                  await captainGetIt<CaptainSessionStore>().clearSession();
                  if (context.mounted) Navigator.of(context).maybePop();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
