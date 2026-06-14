import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingBottomControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingBottomControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicators
          Row(
            children: List.generate(totalPages, (index) {
              final isActive = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: isActive ? 24 : 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          
          // Next/Get Started Button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLastPage
                ? ElevatedButton(
                    key: const ValueKey('get_started'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onNext();
                    },
                    child: const Text('Get Started'),
                  )
                : IconButton.filled(
                    key: const ValueKey('next'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onNext();
                    },
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                  ),
          ),
        ],
      ),
    );
  }
}
