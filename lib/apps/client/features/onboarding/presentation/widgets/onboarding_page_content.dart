import 'package:flutter/material.dart';
import '../animations/fade_slide_transition.dart';

class OnboardingPageContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget heroImage;
  final bool isVisible;

  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.heroImage,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Hero Image Wrapper with floating animation applied externally
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(child: heroImage),
          ),
          const Spacer(flex: 1),
          // Staggered Title
          FadeSlideTransition(
            delay: const Duration(milliseconds: 100),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Staggered Subtitle
          FadeSlideTransition(
            delay: const Duration(milliseconds: 300),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
