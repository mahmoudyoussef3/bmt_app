import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_brand_mark.dart';

import '../widgets/captain_splash_backdrop.dart';
import '../widgets/captain_splash_progress.dart';
import '../widgets/captain_splash_wordmark.dart';

/// Branded animated splash shown while the auth gate resolves which root the
/// captain belongs on (operational session / local session / pending request /
/// sign in).
///
/// Motion sequence (intro ~1100ms, then a looping progress shimmer):
///   0ms   – ambient glow breathes behind the brand
///   80ms  – brand mark scales 0.7 → 1.0 with a soft settle
///   260ms – wordmark fades in and slides up
///   520ms – tagline fades in
///   760ms – progress track reveals and animates indefinitely
///
/// The gate owns the actual transition — this widget never self-dismisses, so
/// a slow session read simply keeps the loop running rather than racing a
/// timer the way a fixed-duration splash would.
class CaptainSplashScreen extends StatefulWidget {
  const CaptainSplashScreen({super.key});

  @override
  State<CaptainSplashScreen> createState() => _CaptainSplashScreenState();
}

class _CaptainSplashScreenState extends State<CaptainSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _ambient;

  late final Animation<double> _markScale;
  late final Animation<double> _markOpacity;
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

    _markScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.07, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _markOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.07, 0.4, curve: Curves.easeOut),
    );
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
      backgroundColor: CaptainColors.backgroundFor(context),
      body: Stack(
        children: [
          CaptainSplashBackdrop(animation: _ambient),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _markOpacity,
                  child: ScaleTransition(
                    scale: _markScale,
                    child: const CaptainBrandMark(),
                  ),
                ),
                const SizedBox(height: 22),
                CaptainSplashWordmark(reveal: _wordmarkReveal),
                const SizedBox(height: 14),
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Text(
                    'رحلاتك في مكان واحد',
                    style: CaptainTypography.bodyMedium(context).copyWith(
                      color: CaptainColors.textSecondaryFor(context),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 56),
              child: FadeTransition(
                opacity: _progressOpacity,
                child: const CaptainSplashProgress(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
