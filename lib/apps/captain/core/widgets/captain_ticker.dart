import 'dart:async';

import 'package:flutter/material.dart';

/// Rebuilds its subtree on a fixed interval with a fresh `now`.
///
/// Anything that renders "in 20 minutes" or "3 minutes ago" is a function of
/// the current time, but a `StatelessWidget` only samples `DateTime.now()`
/// when something else happens to rebuild it. On the captain home screen that
/// is a realtime trip change — which can be hours apart — so a countdown
/// computed once at load kept reporting the gap that existed when the screen
/// opened, long after it had elapsed. The wall clock has to drive these, not
/// the data stream.
class CaptainTicker extends StatefulWidget {
  const CaptainTicker({
    super.key,
    required this.builder,
    this.interval = const Duration(seconds: 20),
  });

  final Widget Function(BuildContext context, DateTime now) builder;

  /// Kept well under a minute so a minute-granularity label is never visibly
  /// behind the phone's own clock.
  final Duration interval;

  @override
  State<CaptainTicker> createState() => _CaptainTickerState();
}

class _CaptainTickerState extends State<CaptainTicker> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(CaptainTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
