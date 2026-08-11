import 'dart:async';

import 'package:flutter/material.dart';

class CaptainTicker extends StatefulWidget {
  const CaptainTicker({
    super.key,
    required this.builder,
    this.interval = const Duration(seconds: 20),
  });

  final Widget Function(BuildContext context, DateTime now) builder;

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
