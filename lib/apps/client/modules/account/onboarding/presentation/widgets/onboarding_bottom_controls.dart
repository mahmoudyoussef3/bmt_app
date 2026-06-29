import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

class OnboardingBottomControls extends StatelessWidget {
  const OnboardingBottomControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = currentPage == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(totalPages, (index) {
                final isActive = index == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(right: 8),
                  height: 8,
                  width: isActive ? 26 : 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? ClientColors.primary
                        : ClientColors.primary.withAlpha(46),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: PressableScale(
              onTap: () {
                HapticFeedback.lightImpact();
                onNext();
              },
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: Container(
                  height: 56,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLastPage ? 26 : 18,
                  ),
                  decoration: BoxDecoration(
                    color: ClientColors.primary,
                    borderRadius: BorderRadius.circular(isLastPage ? 18 : 28),
                    boxShadow: [
                      BoxShadow(
                        color: ClientColors.primary.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLastPage)
                        Flexible(
                          child: Text(
                            l10n.onboarding_getStarted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      if (isLastPage) const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
