import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/home/presentation/screens/client_splash_screen.dart';

/// Holds [ClientSplashScreen] on screen until the app state is resolved *and*
/// a minimum duration has passed, then cross-fades into the landing screen.
///
/// Onboarding + auth both resolve from local storage in a few milliseconds, so
/// without a floor the splash is torn down before its 1100ms intro can play.
class ClientSplashGate extends StatefulWidget {
  const ClientSplashGate({
    super.key,
    required this.isReady,
    required this.builder,
    this.minimumDuration = const Duration(milliseconds: 2000),
  });

  /// Whether the destination screen can be resolved yet.
  final bool isReady;

  /// Builds the screen shown once the splash is dismissed.
  final WidgetBuilder builder;

  final Duration minimumDuration;

  @override
  State<ClientSplashGate> createState() => _ClientSplashGateState();
}

class _ClientSplashGateState extends State<ClientSplashGate> {
  Timer? _minimumTimer;
  bool _minimumElapsed = false;

  @override
  void initState() {
    super.initState();
    _minimumTimer = Timer(widget.minimumDuration, () {
      if (mounted) setState(() => _minimumElapsed = true);
    });
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSplash = !_minimumElapsed || !widget.isReady;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: showSplash
          
          ? const ClientSplashScreen(key: ValueKey('client-splash'))
          : KeyedSubtree(
              key: const ValueKey('client-landing'),
              child: widget.builder(context),
            ),
    );
  }
}
