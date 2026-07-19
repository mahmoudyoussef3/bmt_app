import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

import '../widgets/welcome_actions.dart';
import '../widgets/welcome_hero.dart';
import '../widgets/welcome_language_toggle.dart';

/// The entry screen after onboarding. Email/password is the only real path;
/// Google, Apple and Phone are presented but mocked ("coming soon").
///
/// The direction follows the app locale (RTL for Arabic) — the screen no longer
/// forces LTR, so the Arabic layout mirrors correctly.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        WelcomeLanguageToggle(),
                        Spacer(flex: 2),
                        WelcomeHero(),
                        Spacer(flex: 3),
                        WelcomeActions(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
