import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'widgets/splash_glow_backdrop.dart';
import 'widgets/splash_wordmark.dart';
import 'widgets/splash_progress_track.dart';

/// Branded animated splash shown while the app resolves onboarding + auth state.
///
/// Motion sequence (intro ~1100ms, then a looping progress shimmer):
///   0ms   – brand mark is already on screen, unanimated, exactly where the
///           native launch frame drew it, while the ambient glow breathes
///   260ms – wordmark fades in and slides up
///   520ms – tagline fades in
///   760ms – progress track reveals and animates indefinitely
///
/// The mark deliberately does not scale or fade in: the OS has been showing the
/// identical tile since the process started, so animating it would read as a
/// pop rather than an entrance.
///
/// The parent state machine (OnboardingCubit / auth StreamBuilder) owns the
/// actual navigation transition — this widget never self-dismisses.
class ClientSplashScreen extends StatefulWidget {
  const ClientSplashScreen({super.key});

  @override
  State<ClientSplashScreen> createState() => _ClientSplashScreenState();
}

class _ClientSplashScreenState extends State<ClientSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _ambient;

  late final Animation<double> _wordmarkReveal;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _progressOpacity;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _wordmarkReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.24, 0.62, curve: Curves.easeOutCubic),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.47, 0.78, curve: Curves.easeIn),
    );
    _progressOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      body: Stack(
        children: [
          SplashGlowBackdrop(animation: _ambient),
          // The mark is pinned to the exact center of the screen — the spot the
          // native splash leaves it in — and the lockup hangs off it, so the
          // handoff reveals text instead of sliding the brand upward.
          Center(
            child: SizedBox(
              height: kSplashBrandMarkSize,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const SplashBrandMark(),
                  Positioned(
                    top: kSplashBrandMarkSize + 22,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        SplashWordmark(reveal: _wordmarkReveal),
                        const SizedBox(height: 14),
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: Text(
                            context.l10n.splash_tagline,
                            style: ClientTypography.bodyMedium(context)
                                .copyWith(
                                  color: ClientColors.textTertiaryFor(context),
                                  letterSpacing: 0.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 56),
              child: FadeTransition(
                opacity: _progressOpacity,
                child: const SplashProgressTrack(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
