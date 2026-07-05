import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../routes/auth_routes.dart';
import '../widgets/social_login_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Switcher (Top Right)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ClientColors.surfaceFor(context),
                    borderRadius: BorderRadius.circular(ClientRadius.pill),
                    border: Border.all(color: ClientColors.borderFor(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: ClientColors.textSecondaryFor(context),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'English',
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: ClientColors.textPrimaryFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Logo & App Name
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ClientColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ClientColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ClientColors.primary.withAlpha(80),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Welcome to BMT',
                textAlign: TextAlign.center,
                style: ClientTypography.displayMedium(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: ClientColors.primaryFor(context),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'The leading platform for smart and comfortable transportation. Book your trip easily and securely.',
                textAlign: TextAlign.center,
                style: ClientTypography.bodyLarge(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Action Buttons
              ClientButton(
                label: 'Continue with Phone',
                onPressed: () {
                  Navigator.of(context).pushNamed('/phone-login');
                },
                icon: const Icon(
                  Icons.phone_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              ClientButton.secondary(
                label: 'Continue with Email',
                onPressed: () {
                  Navigator.of(context).pushNamed(AuthRoutes.signIn);
                },
                icon: Icon(
                  Icons.email_rounded,
                  size: 20,
                  color: ClientColors.primaryFor(context),
                ),
              ),

              const SizedBox(height: 24),

              // Social Login section
              const SocialLoginButtons(),

              const SizedBox(height: 16),

              // Guest Button
              ClientButton.text(
                label: 'Continue as Guest',
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              ),

              const SizedBox(height: 24),

              // Footer Terms
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: ClientTypography.labelSmall(context).copyWith(
                  color: ClientColors.textTertiaryFor(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
