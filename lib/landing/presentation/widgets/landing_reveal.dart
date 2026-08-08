import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/motion_preference.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Fades and lifts [child] into place the first time it scrolls into view.
///
/// Self-contained (no visibility-detector package): it listens to the
/// nearest [Scrollable]'s position and checks its own [RenderBox] against the
/// viewport on every tick, same idea as a scroll-spy. Fires once — a
/// marketing page that keeps re-animating a section every time the visitor
/// scrolls past it reads as a demo, not a product.
class LandingReveal extends StatefulWidget {
  const LandingReveal({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<LandingReveal> createState() => _LandingRevealState();
}

class _LandingRevealState extends State<LandingReveal> {
  bool _visible = AppMotion.reduceMotion;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visible) return;
    final scrollable = Scrollable.maybeOf(context);
    final newPosition = scrollable?.position;
    if (newPosition != _position) {
      _position?.removeListener(_checkVisibility);
      _position = newPosition;
      _position?.addListener(_checkVisibility);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
    }
  }

  void _checkVisibility() {
    if (_visible || !mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final position = renderObject.localToGlobal(Offset.zero);
    if (position.dy < screenHeight * 0.92) {
      if (widget.delay == Duration.zero) {
        setState(() => _visible = true);
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) setState(() => _visible = true);
        });
      }
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppTokens.motionSlow,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        duration: AppTokens.motionSlow,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
