import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Owns the hub's [ConfettiController] and paints its overlay above [child].
///
/// This exists so the screens themselves stay stateless: a confetti controller
/// is exactly the "genuinely ephemeral UI state" a [StatefulWidget] is for, so
/// it is isolated here rather than dragging a whole screen into `setState`.
/// Descendants fire it with `LoyaltyCelebrationHost.celebrate(context)`.
class LoyaltyCelebrationHost extends StatefulWidget {
  const LoyaltyCelebrationHost({super.key, required this.child});

  final Widget child;

  /// Fires a burst. A no-op when no host is above [context], so a reward tile
  /// rendered outside the hub still redeems rather than asserting.
  static void celebrate(BuildContext context) {
    context
        .dependOnInheritedWidgetOfExactType<_LoyaltyCelebrationScope>()
        ?.state
        .celebrate();
  }

  @override
  State<LoyaltyCelebrationHost> createState() => _LoyaltyCelebrationHostState();
}

class _LoyaltyCelebrationHostState extends State<LoyaltyCelebrationHost> {
  final ConfettiController _confetti = ConfettiController();

  void celebrate() => _confetti.fire();

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LoyaltyCelebrationScope(
      state: this,
      child: Stack(
        children: [widget.child, ConfettiOverlay(controller: _confetti)],
      ),
    );
  }
}

class _LoyaltyCelebrationScope extends InheritedWidget {
  const _LoyaltyCelebrationScope({required this.state, required super.child});

  final _LoyaltyCelebrationHostState state;

  @override
  bool updateShouldNotify(_LoyaltyCelebrationScope oldWidget) => false;
}
