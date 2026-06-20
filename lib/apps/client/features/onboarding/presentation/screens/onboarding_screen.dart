import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../animations/animated_background_blob.dart';
import '../widgets/onboarding_bottom_controls.dart';
import '../widgets/onboarding_page_content.dart';
import '../widgets/onboarding_scene.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _cyan = Color(0xFF06B6D4);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<OnboardingPageData> _pages(AppLocalizations l10n) => [
    OnboardingPageData(
      title: l10n.onboarding_page1Title,
      body: l10n.onboarding_page1Body,
      accent: ClientColors.primary,
      scene: OnboardingScene(
        accent: ClientColors.primary,
        centerIcon: Icons.directions_bus_filled_rounded,
        cards: const [
          OnboardingFloatingCard(
            icon: Icons.near_me_rounded,
            title: 'Cairo → Zayed',
            alignment: Alignment(-0.98, -0.86),
            floatMagnitude: 6,
            floatSeconds: 5,
          ),
          OnboardingFloatingCard(
            icon: Icons.schedule_rounded,
            title: '08:40 AM',
            subtitle: 'Next trip',
            alignment: Alignment(0.98, -0.46),
            floatSeconds: 4,
          ),
          OnboardingFloatingCard(
            icon: Icons.event_seat_rounded,
            title: 'Seat A12',
            subtitle: 'Confirmed',
            alignment: Alignment(0.9, 0.92),
            accent: ClientColors.journeyGreen,
            floatMagnitude: 8,
            floatSeconds: 6,
          ),
        ],
      ),
      features: [
        OnboardingFeature(
          Icons.event_seat_rounded,
          l10n.onboarding_page1FeatureA,
        ),
        OnboardingFeature(Icons.route_rounded, l10n.onboarding_page1FeatureB),
      ],
    ),
    OnboardingPageData(
      title: l10n.onboarding_page2Title,
      body: l10n.onboarding_page2Body,
      accent: _cyan,
      scene: OnboardingScene(
        accent: _cyan,
        centerIcon: Icons.navigation_rounded,
        cards: const [
          OnboardingFloatingCard(
            icon: Icons.my_location_rounded,
            title: 'Live',
            subtitle: 'Updated now',
            alignment: Alignment(-0.98, -0.86),
            floatSeconds: 5,
          ),
          OnboardingFloatingCard(
            icon: Icons.timer_outlined,
            title: 'ETA 12 min',
            subtitle: 'On time',
            alignment: Alignment(0.98, -0.46),
            accent: ClientColors.journeyGreen,
            floatMagnitude: 8,
            floatSeconds: 4,
          ),
          OnboardingFloatingCard(
            icon: Icons.directions_bus_rounded,
            title: 'On the way',
            alignment: Alignment(-0.9, 0.92),
            floatMagnitude: 6,
            floatSeconds: 6,
          ),
        ],
      ),
      features: [
        OnboardingFeature(
          Icons.my_location_rounded,
          l10n.onboarding_page2FeatureA,
        ),
        OnboardingFeature(
          Icons.schedule_rounded,
          l10n.onboarding_page2FeatureB,
        ),
      ],
    ),
    OnboardingPageData(
      title: l10n.onboarding_page3Title,
      body: l10n.onboarding_page3Body,
      accent: ClientColors.journeyPurple,
      scene: OnboardingScene(
        accent: ClientColors.journeyPurple,
        centerIcon: Icons.card_membership_rounded,
        cards: const [
          OnboardingFloatingCard(
            icon: Icons.verified_rounded,
            title: 'Monthly pass',
            subtitle: 'Active',
            alignment: Alignment(-0.98, -0.86),
            accent: ClientColors.journeyGreen,
            floatSeconds: 5,
          ),
          OnboardingFloatingCard(
            icon: Icons.lock_rounded,
            title: 'Paid securely',
            alignment: Alignment(0.98, -0.46),
            accent: ClientColors.primary,
            floatMagnitude: 8,
            floatSeconds: 4,
          ),
          OnboardingFloatingCard(
            icon: Icons.support_agent_rounded,
            title: 'Support 24/7',
            alignment: Alignment(0.9, 0.92),
            floatMagnitude: 6,
            floatSeconds: 6,
          ),
        ],
      ),
      features: [
        OnboardingFeature(
          Icons.card_membership_rounded,
          l10n.onboarding_page3FeatureA,
        ),
        OnboardingFeature(Icons.lock_rounded, l10n.onboarding_page4FeatureA),
        OnboardingFeature(
          Icons.support_agent_rounded,
          l10n.onboarding_page4FeatureB,
        ),
      ],
    ),
  ];

  void _onNext(int total) {
    if (_currentPage < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    _complete();
  }

  void _complete() => context.read<OnboardingCubit>().completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);
    final size = MediaQuery.sizeOf(context);
    final isLast = _currentPage == pages.length - 1;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: ClientColors.surfaceFor(context),
        body: Stack(
          children: [
            AnimatedBackgroundBlob(
              color: ClientColors.primary,
              size: 400,
              initialPosition: const Offset(-110, -120),
              animationDuration: const Duration(seconds: 12),
            ),
            AnimatedBackgroundBlob(
              color: _cyan,
              size: 300,
              initialPosition: Offset(size.width - 150, size.height - 300),
              animationDuration: const Duration(seconds: 15),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: isLast ? 0 : 1,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, right: 12),
                        child: TextButton(
                          onPressed: isLast ? null : _onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: ClientColors.textSecondaryFor(
                              context,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(l10n.onboarding_skip),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        HapticFeedback.selectionClick();
                      },
                      itemBuilder: (context, index) => OnboardingPageContent(
                        data: pages[index],
                        isVisible: _currentPage == index,
                      ),
                    ),
                  ),
                  OnboardingBottomControls(
                    currentPage: _currentPage,
                    totalPages: pages.length,
                    onNext: () => _onNext(pages.length),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
