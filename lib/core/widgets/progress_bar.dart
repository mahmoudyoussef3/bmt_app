import 'package:flutter/material.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; 
  const AppProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackWidth = MediaQuery.sizeOf(context).width * 0.42;
        final barWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : fallbackWidth;

        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: barWidth,
            height: 10,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(12),
                  ),
                ),
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
