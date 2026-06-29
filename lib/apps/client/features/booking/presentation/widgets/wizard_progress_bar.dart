import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

const _labels = ['Stops', 'Trip', 'Seat', 'Package', 'Summary', 'Payment'];

class WizardProgressBar extends StatelessWidget {
  const WizardProgressBar({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? ClientColors.darkPrimary : ClientColors.primary;
    final doneColor = isDark ? ClientColors.darkPrimaryStrong : ClientColors.primaryHover;
    final emptyColor = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE5EAF2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: List.generate(_labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                final idx = i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: idx < step ? doneColor : emptyColor,
                  ),
                );
              }
              final idx = i ~/ 2;
              final isDone = idx < step;
              final isActive = idx == step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? doneColor
                      : isActive
                          ? activeColor
                          : emptyColor,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: ClientTypography.labelSmall(context).copyWith(
                            color: isActive ? Colors.white : ClientColors.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _labels[step],
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
            ),
          ),
        ),
      ],
    );
  }
}
