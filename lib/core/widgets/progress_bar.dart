import 'package:flutter/material.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; // 0..1
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
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: barWidth,
            height: 8,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(15),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
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
