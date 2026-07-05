import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// A slim, indefinitely animating progress track that reads as "getting things
/// ready" without the harshness of a spinner. A highlighted segment sweeps
/// left-to-right across a muted rail.
class SplashProgressTrack extends StatefulWidget {
  const SplashProgressTrack({super.key, this.width = 132});

  final double width;

  @override
  State<SplashProgressTrack> createState() => _SplashProgressTrackState();
}

class _SplashProgressTrackState extends State<SplashProgressTrack>
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
    return SizedBox(
      width: widget.width,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: ClientColors.primary.withAlpha(38),
              ),
              child: const SizedBox.expand(),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Sweep a highlighted segment from fully-left to fully-right.
                final x = (_controller.value * 2) - 1;
                return Align(
                  alignment: Alignment(x, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ClientColors.primary.withAlpha(0),
                            ClientColors.primaryFor(context),
                            ClientColors.primary.withAlpha(0),
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
    );
  }
}
