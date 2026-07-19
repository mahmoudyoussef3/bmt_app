import 'package:flutter/material.dart';

/// The two soft corner glows behind the subscription flow.
class SubscriptionBackground extends StatelessWidget {
  const SubscriptionBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        PositionedDirectional(
          top: -80,
          end: -80,
          child: _CircleGlow(color: scheme.primary.withAlpha(20)),
        ),
        PositionedDirectional(
          bottom: -60,
          start: -80,
          child: _CircleGlow(color: scheme.secondary.withAlpha(15)),
        ),
      ],
    );
  }
}

class _CircleGlow extends StatelessWidget {
  const _CircleGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}
