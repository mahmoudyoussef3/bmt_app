import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

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
