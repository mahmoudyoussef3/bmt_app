import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/app_spacing.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_primary_button.dart';

/// Post-authentication success screen with animation placeholder.
class AuthSuccessScreen extends StatefulWidget {
  const AuthSuccessScreen({super.key});

  @override
  State<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends State<AuthSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  void _exploreTrips(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pushNamedAndRemoveUntil('/home', (_) => false);
    navigator.pushNamed('/daily-booking');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        scheme.secondary.withAlpha(90),
                        scheme.primary.withAlpha(120),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withAlpha(50),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
              AppSpacing.hLg,
              Text(
                'You\'re all set!',
                textAlign: TextAlign.center,
                style: AppTextThemes.headlineStrong(scheme),
              ),
              AppSpacing.hSm,
              Text(
                'Welcome to Mega Transportation. Your account is ready — '
                'book your next commute or explore available trips.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(190),
                  height: 1.55,
                ),
              ),
              const Spacer(),
              AuthPrimaryButton(
                label: 'Go To Home',
                onPressed: () => _goHome(context),
              ),
              AppSpacing.hSm,
              AuthPrimaryButton(
                label: 'Explore Trips',
                outline: true,
                onPressed: () => _exploreTrips(context),
              ),
              AppSpacing.hMd,
            ],
          ),
        ),
      ),
    );
  }
}
