import 'package:flutter/material.dart';

/// Brand mark for auth entry screens.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(60),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.directions_bus_rounded,
        size: size * 0.48,
        color: scheme.onPrimary,
      ),
    );
  }
}
