import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';

import '../../../onboarding/presentation/cubit/captain_onboarding_cubit.dart';
import '../../../onboarding/presentation/screens/captain_onboarding_flow.dart';
import '../../../onboarding/presentation/screens/captain_welcome_home.dart';

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
