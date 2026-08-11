import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'confetti_controller.dart';
import 'confetti_painter.dart';

/// A self-contained celebration layer. Stack it over the screen content and
/// call `controller.fire()` to celebrate.
///
/// Stateful by necessity: it owns a vsync [Ticker], which requires a
/// [TickerProvider] and therefore an element-bound [State]. Nothing above it
/// ever rebuilds — the simulation only repaints this layer, which sits behind
/// its own [RepaintBoundary].
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({required this.controller, super.key});

  final ConfettiController controller;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Size _bounds = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.isActive && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onTick(Duration _) {
    
    if (_bounds.isEmpty || !_bounds.isFinite) return;
    widget.controller.spawnPendingBurst(_bounds);
    if (!widget.controller.advance(_bounds)) {
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _bounds = constraints.biggest;
          return RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: ConfettiPainter(widget.controller),
            ),
          );
        },
      ),
    );
  }
}
