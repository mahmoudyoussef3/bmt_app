import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Branded animated splash shown while the app resolves onboarding + auth state.
///
/// Animation sequence (total ~900ms):
///   0ms  – wordmark fades in and scales 0.85 → 1.0 (400ms, easeOut)
///   300ms – tagline fades in (350ms, easeIn)
///   700ms – pulsing indicator fades in (200ms)
///
/// The parent state machine (OnboardingCubit / StreamBuilder) handles the
/// actual navigation transition — this widget never self-dismisses.
class ClientSplashScreen extends StatefulWidget {
  const ClientSplashScreen({super.key});

  @override
  State<ClientSplashScreen> createState() => _ClientSplashScreenState();
}

class _ClientSplashScreenState extends State<ClientSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _wordmarkScale;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _indicatorOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _wordmarkOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _wordmarkScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.33, 0.72, curve: Curves.easeIn),
    );
    _indicatorOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.78, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceFor(context),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Wordmark
            FadeTransition(
              opacity: _wordmarkOpacity,
              child: ScaleTransition(scale: _wordmarkScale, child: _Wordmark()),
            ),

            const SizedBox(height: 16),

            // Tagline
            FadeTransition(
              opacity: _taglineOpacity,
              child: Text(
                'Your journey, simplified.',
                style: ClientTypography.bodyMedium(context).copyWith(
                  color: ClientColors.textTertiaryFor(context),
                  letterSpacing: 0.3,
                ),
              ),
            ),

            const SizedBox(height: 56),

            // Loading indicator
            FadeTransition(
              opacity: _indicatorOpacity,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ClientColors.primaryMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ClientColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.route_rounded,
            color: ClientColors.textInverse,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        // App name
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Easy',
                style: ClientTypography.displayMedium(context).copyWith(
                  color: ClientColors.textPrimaryFor(context),
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'Way',
                style: ClientTypography.displayMedium(
                  context,
                ).copyWith(color: ClientColors.primary, height: 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
