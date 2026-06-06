import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/app_spacing.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_logo.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/social_sign_in_button.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/terms_footer.dart';

/// Onboarding / auth entry screen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 520;
            final horizontal = wide ? (constraints.maxWidth - 440) / 2 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const Center(child: AuthLogo(size: 88)),
                    AppSpacing.hLg,
                    Text(
                      'Welcome to Mega Transportation',
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    AppSpacing.hMd,
                    Text(
                      'Book daily commutes, track your shuttle in real time, '
                      'and manage your rides — all in one place.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withAlpha(190),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 56),
                    AuthPrimaryButton(
                      label: 'Continue with Phone Number',
                      onPressed: () {
                        Navigator.pushNamed(context, AuthRoutes.phone);
                      },
                    ),
                    AppSpacing.hMd,
                    SocialSignInButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_rounded,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AuthRoutes.registration,
                          arguments: const {'via': 'google'},
                        );
                      },
                    ),
                    AppSpacing.hSm,
                    SocialSignInButton(
                      label: 'Continue with Apple',
                      icon: Icons.apple_rounded,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AuthRoutes.registration,
                          arguments: const {'via': 'apple'},
                        );
                      },
                    ),
                    AppSpacing.hLg,
                    const TermsFooter(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
