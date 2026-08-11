import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_brand_mark.dart';

import '../widgets/captain_splash_backdrop.dart';
import '../widgets/captain_splash_progress.dart';
import '../widgets/captain_splash_wordmark.dart';

const double _brandMarkSize = 96;

class CaptainSplashScreen extends StatefulWidget {
  const CaptainSplashScreen({super.key});

  @override
  State<CaptainSplashScreen> createState() => _CaptainSplashScreenState();
}

class _CaptainSplashScreenState extends State<CaptainSplashScreen>
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
      backgroundColor: CaptainColors.backgroundFor(context),
      body: Stack(
        children: [
          CaptainSplashBackdrop(animation: _ambient),
          Center(
            child: SizedBox(
              height: _brandMarkSize,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const CaptainBrandMark(size: _brandMarkSize),
                  Positioned(
                    top: _brandMarkSize + 22,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        CaptainSplashWordmark(reveal: _wordmarkReveal),
                        const SizedBox(height: 14),
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: Text(
                            'رحلاتك في مكان واحد',
                            style: CaptainTypography.bodyMedium(context)
                                .copyWith(
                                  color: CaptainColors.textSecondaryFor(
                                    context,
                                  ),
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
                child: const CaptainSplashProgress(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
