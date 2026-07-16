import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

/// A slim, indefinitely animating progress track that reads as "getting things
/// ready" without the harshness of a spinner. A highlighted segment sweeps
/// across a muted rail.
class CaptainSplashProgress extends StatefulWidget {
  const CaptainSplashProgress({super.key, this.width = 132});

  final double width;

  @override
  State<CaptainSplashProgress> createState() => _CaptainSplashProgressState();
}

class _CaptainSplashProgressState extends State<CaptainSplashProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: widget.width,
      height: 4,
      child: ClipRRect(
        borderRadius: CaptainDesignTokens.brPill,
        // The sweep is a physical motion, not language — it runs left-to-right
        // regardless of the app's ambient RTL.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: scheme.primary.withAlpha(38)),
                child: const SizedBox.expand(),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Align(
                    // Sweep from fully-left to fully-right.
                    alignment: Alignment((_controller.value * 2) - 1, 0),
                    child: FractionallySizedBox(
                      widthFactor: 0.4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withAlpha(0),
                              scheme.primary,
                              scheme.primary.withAlpha(0),
                            ],
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
