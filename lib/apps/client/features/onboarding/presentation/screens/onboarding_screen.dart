import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../widgets/onboarding_page_content.dart';
import '../widgets/onboarding_bottom_controls.dart';
import '../animations/animated_background_blob.dart';
import '../animations/floating_animation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }

  void _completeOnboarding() {
    context.read<OnboardingCubit>().completeOnboarding();
    // The navigation will be handled by the route listener in client_app or wherever the stream builder is.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Blobs
          AnimatedBackgroundBlob(
            color: ClientColors.primary,
            size: 400,
            initialPosition: Offset(-100, -100),
            animationDuration: const Duration(seconds: 12),
          ),
          AnimatedBackgroundBlob(
            color: const Color(0xFF06B6D4), // Cyan
            size: 300,
            initialPosition: Offset(
              MediaQuery.of(context).size.width - 150,
              MediaQuery.of(context).size.height - 300,
            ),
            animationDuration: const Duration(seconds: 15),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar (Skip Button)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: ClientColors.textSecondaryFor(context),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

                // Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      HapticFeedback.selectionClick();
                    },
                    children: [
                      OnboardingPageContent(
                        isVisible: _currentPage == 0,
                        title: 'Move Smarter Every Day',
                        subtitle:
                            'Book your daily rides in seconds and enjoy a smooth transportation experience built around your schedule.',
                        heroImage: FloatingAnimation(
                          magnitude: 8,
                          duration: const Duration(seconds: 4),
                          child: Image.asset(
                            'assets/images/onboarding/smart_transport.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      OnboardingPageContent(
                        isVisible: _currentPage == 1,
                        title: 'Track Every Journey Live',
                        subtitle:
                            'Know exactly where your trip is, when it arrives, and stay updated throughout the entire journey.',
                        heroImage: FloatingAnimation(
                          magnitude: 12,
                          duration: const Duration(seconds: 5),
                          child: Image.asset(
                            'assets/images/onboarding/live_tracking.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      OnboardingPageContent(
                        isVisible: _currentPage == 2,
                        title: 'Save More With Smart Passes',
                        subtitle:
                            'Unlock monthly subscriptions, discounted packages, and a premium commuting experience.',
                        heroImage: FloatingAnimation(
                          magnitude: 10,
                          duration: const Duration(seconds: 3),
                          child: Image.asset(
                            'assets/images/onboarding/subscriptions.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Controls
                OnboardingBottomControls(
                  currentPage: _currentPage,
                  totalPages: 3,
                  onNext: _onNext,
                  onSkip: _onSkip,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
