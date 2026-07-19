import 'package:flutter/material.dart';

/// The two tinted circles bleeding off the corners of a package card.
class PackageCardBackdrop extends StatelessWidget {
  const PackageCardBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final alpha = Theme.of(context).brightness == Brightness.dark ? 15 : 8;

    return IgnorePointer(
      child: Stack(
        children: [
          PositionedDirectional(
            end: -40,
            top: -40,
            child: _Circle(size: 120, color: scheme.primary.withAlpha(alpha)),
          ),
          PositionedDirectional(
            start: -20,
            bottom: -20,
            child: _Circle(size: 80, color: scheme.secondary.withAlpha(alpha)),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
