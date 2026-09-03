import 'package:flutter/material.dart';

/// Hands the page's scroll ticks down to the [LandingReveal]s under it.
///
/// The reveals attach their own listener rather than this being an
/// [InheritedNotifier]: an inherited notifier would rebuild all eighteen
/// sections on every scroll frame, where each reveal needs to be told exactly
/// once — after which it drops the listener for good.
class LandingRevealScope extends InheritedWidget {
  const LandingRevealScope({
    super.key,
    required this.ticker,
    required super.child,
  });

  /// Anything that fires while the page scrolls — in practice the page's own
  /// [ScrollController].
  final Listenable ticker;

  static Listenable? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LandingRevealScope>()?.ticker;

  @override
  bool updateShouldNotify(LandingRevealScope oldWidget) =>
      oldWidget.ticker != ticker;
}

/// Fades and lifts its child in the first time it enters the viewport.
///
/// A marketing page this long is read in passes, and eighteen bands that all
/// arrive fully formed give the reader no sense of moving through a document.
/// The reveal is deliberately small — 18px and half a second, once per
/// section — so it reads as the page settling rather than as an effect.
///
/// Outside a [LandingRevealScope] (the per-section capture harness) the child
/// is shown immediately: there is no scroll to wait for.
class LandingReveal extends StatefulWidget {
  const LandingReveal({super.key, required this.child, this.rise = 18});

  final Widget child;

  /// How far below its resting place the child starts.
  final double rise;

  @override
  State<LandingReveal> createState() => _LandingRevealState();
}

class _LandingRevealState extends State<LandingReveal> {
  Listenable? _ticker;
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ticker = LandingRevealScope.maybeOf(context);
    if (identical(ticker, _ticker)) return;
    _ticker?.removeListener(_check);
    _ticker = ticker;
    if (ticker == null) {
      _shown = true;
      return;
    }
    ticker.addListener(_check);
    // The first frame decides everything above the fold — the hero fades in
    // on load, the rest wait for a scroll tick.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _ticker?.removeListener(_check);
    super.dispose();
  }

  /// Reveals once the child's top edge has risen into the last tenth of the
  /// viewport: early enough that the animation is over before the reader
  /// arrives, late enough that it is not spent off-screen.
  void _check() {
    if (_shown || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    if (box.localToGlobal(Offset.zero).dy >
        MediaQuery.sizeOf(context).height * 0.92) {
      return;
    }
    _ticker?.removeListener(_check);
    setState(() => _shown = true);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _shown ? 1 : 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: widget.child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        // A transform, not padding: the section must not move in layout, or
        // every reveal below it would reflow as this one settles.
        child: Transform.translate(
          offset: Offset(0, (1 - t) * widget.rise),
          child: child,
        ),
      ),
    );
  }
}
