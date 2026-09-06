import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The marketing page's motion tokens.
///
/// One vocabulary for the whole site: things arrive by fading up over
/// [reveal], a run of siblings arrives [stagger] apart, and anything that
/// fills — a meter, a bar, a gauge, a line — draws over [draw] once its own
/// card has arrived. Every duration on the page comes from here rather than
/// being spelled out at the call site, so the page reads as one document
/// settling rather than as twenty separate effects.
class LandingMotion {
  const LandingMotion._();

  /// How long a single element takes to fade and lift into place.
  static const Duration reveal = Duration(milliseconds: 620);

  /// The gap between two siblings in a staggered run.
  static const Duration stagger = Duration(milliseconds: 70);

  /// How long a figure takes to fill: meters, bars, the occupancy ring, the
  /// finance lines. Deliberately slower than [reveal] — the card lands first
  /// and the number grows into it.
  static const Duration draw = Duration(milliseconds: 900);

  /// Deceleration for everything above. Nothing on this page overshoots.
  static const Curve curve = Curves.easeOutCubic;

  /// How far below its resting place a revealed element starts.
  static const double rise = 22;

  /// The shorter lift used by cells inside a grid, where a full [rise] on six
  /// cards at once reads as the row sliding rather than settling.
  static const double riseSmall = 14;
}

/// Hands the page's scroll ticks down to the [LandingReveal]s under it, and
/// marks the subtree as the one place motion is allowed to run.
///
/// The reveals attach their own listener rather than this being an
/// [InheritedNotifier]: an inherited notifier would rebuild all eighteen
/// sections on every scroll frame, where each reveal needs to be told exactly
/// once — after which it drops the listener for good.
///
/// **Outside a scope nothing animates at all.** The per-section capture
/// harness mounts one band with no page around it, and a golden of a band
/// caught mid-fade is a golden of nothing.
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

/// Published by every [LandingReveal] for the reveals nested under it.
///
/// A section's cards do not each watch the scroll position — they watch the
/// section. Only the eighteen band-level reveals measure themselves against
/// the viewport on a scroll tick; everything below them is released by its
/// parent and spends its own delay staggering, which keeps a fling down the
/// page at one `localToGlobal` per band rather than one per card.
class _RevealTrigger extends InheritedWidget {
  const _RevealTrigger({required this.started, required super.child});

  final ValueListenable<bool> started;

  static ValueListenable<bool>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RevealTrigger>()?.started;

  @override
  bool updateShouldNotify(_RevealTrigger oldWidget) =>
      oldWidget.started != started;
}

/// The shared "when does this element get to move?" wiring.
///
/// Three answers, in the order they are asked for: outside a
/// [LandingRevealScope] — or with animations turned off — immediately and
/// without animating; inside another [LandingReveal] — when that one starts;
/// otherwise — when the element's own top edge rises into the viewport.
mixin _RevealBinding<T extends StatefulWidget> on State<T> {
  /// Flips once, when this element starts. Nested reveals listen to it.
  final ValueNotifier<bool> started = ValueNotifier<bool>(false);

  Listenable? _ticker;
  ValueListenable<bool>? _parent;

  /// Runs exactly once. [animate] is false when the element should simply be
  /// in its final state — no scope, reduced motion, or scrolled past unseen.
  void onReveal({required bool animate});

  void bindReveal() {
    if (started.value) return;

    final scope = LandingRevealScope.maybeOf(context);
    final parent = _RevealTrigger.maybeOf(context);
    unbindReveal();

    if (scope == null || MediaQuery.disableAnimationsOf(context)) {
      _fire(animate: false);
      return;
    }
    if (parent != null) {
      if (parent.value) {
        _fire();
      } else {
        _parent = parent..addListener(_onParent);
      }
      return;
    }
    _ticker = scope..addListener(checkReveal);
    // The first frame decides everything above the fold — the hero arrives on
    // load, the rest wait for a scroll tick.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkReveal();
    });
  }

  void unbindReveal() {
    _ticker?.removeListener(checkReveal);
    _ticker = null;
    _parent?.removeListener(_onParent);
    _parent = null;
  }

  void _onParent() {
    if (_parent?.value ?? false) _fire();
  }

  /// Reveals once the element's top edge has risen into the last tenth of the
  /// viewport: early enough that the animation is over before the reader
  /// arrives, late enough that it is not spent off-screen.
  void checkReveal() {
    if (started.value || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top > MediaQuery.sizeOf(context).height * 0.92) return;
    // Already gone past the top of the window — the reader flung by it, so
    // there is nothing left to fade in and a fade would only be noticed on
    // the way back up.
    _fire(animate: top + box.size.height > 0);
  }

  void _fire({bool animate = true}) {
    unbindReveal();
    onReveal(animate: animate);
    // Last, so the children released by this read a parent that has already
    // settled its own controller.
    started.value = true;
  }

  @override
  void dispose() {
    unbindReveal();
    started.dispose();
    super.dispose();
  }
}

/// Fades and lifts its child in the first time it enters the viewport.
///
/// A marketing page this long is read in passes, and eighteen bands that all
/// arrive fully formed give the reader no sense of moving through a document.
/// The reveal is deliberately small — a couple of dozen pixels and half a
/// second, once per element — so it reads as the page settling rather than as
/// an effect.
class LandingReveal extends StatefulWidget {
  const LandingReveal({
    super.key,
    required this.child,
    this.rise = LandingMotion.rise,
    this.delay = Duration.zero,
  });

  final Widget child;

  /// How far below its resting place the child starts.
  final double rise;

  /// Held after the trigger, which is what staggers a run of siblings.
  final Duration delay;

  /// Wraps [children] in reveals one [step] apart — a grid run, a list of
  /// steps, a column of cards.
  static List<Widget> stagger(
    List<Widget> children, {
    double rise = LandingMotion.riseSmall,
    Duration step = LandingMotion.stagger,
    Duration delay = Duration.zero,
  }) => [
    for (var i = 0; i < children.length; i++)
      LandingReveal(rise: rise, delay: delay + step * i, child: children[i]),
  ];

  @override
  State<LandingReveal> createState() => _LandingRevealState();
}

class _LandingRevealState extends State<LandingReveal>
    with SingleTickerProviderStateMixin, _RevealBinding {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + LandingMotion.reveal,
  );

  /// The delay is spent inside the controller rather than on a timer: a timer
  /// that fires after the widget is gone has to be cancelled by hand, and an
  /// [Interval] cannot outlive its controller.
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds /
          (widget.delay + LandingMotion.reveal).inMicroseconds,
      1,
      curve: LandingMotion.curve,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bindReveal();
  }

  @override
  void onReveal({required bool animate}) {
    if (animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: _RevealTrigger(started: started, child: widget.child),
      // The same two wrappers on every frame, settled or not. Dropping them
      // once the reveal finishes looks like a free optimisation and is not:
      // the widget at this slot would change type, which unmounts the whole
      // band and builds it again from scratch — losing every piece of state
      // under it and restarting the meters and charts that had just played.
      // A [RenderOpacity] at alpha 255 skips its layer anyway, and a
      // translation of zero is a matrix multiply.
      builder: (context, child) {
        final t = _t.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          // A transform, not padding: the element must not move in layout, or
          // everything below it would reflow as it settles.
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.rise),
            child: child,
          ),
        );
      },
    );
  }
}

/// Runs a 0 → 1 progress on the same trigger a [LandingReveal] uses, for the
/// things that fill rather than fade: meters, bars, the occupancy ring.
///
/// Those all animate perfectly well on their own with a
/// [TweenAnimationBuilder], and that is exactly the problem — the page builds
/// all eighteen bands at once, so every one of them would play, in full,
/// against a viewport showing the hero. This holds the fill until the card it
/// belongs to has actually been revealed.
class LandingRevealBuilder extends StatefulWidget {
  const LandingRevealBuilder({
    super.key,
    required this.builder,
    this.duration = LandingMotion.draw,
    this.delay = Duration.zero,
  });

  /// Called with 0 → 1, and with a flat 1 wherever motion is off.
  final Widget Function(BuildContext context, double t) builder;

  final Duration duration;
  final Duration delay;

  @override
  State<LandingRevealBuilder> createState() => _LandingRevealBuilderState();
}

class _LandingRevealBuilderState extends State<LandingRevealBuilder>
    with SingleTickerProviderStateMixin, _RevealBinding {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds /
          (widget.delay + widget.duration).inMicroseconds,
      1,
      curve: LandingMotion.curve,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bindReveal();
  }

  @override
  void onReveal({required bool animate}) {
    if (animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, _) => widget.builder(context, _t.value.clamp(0.0, 1.0)),
  );
}
