import 'package:flutter/material.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; // 0..1
  const AppProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 8,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
