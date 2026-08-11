import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/flavors/app_flavor.dart';
import 'captain_reachability_io.dart'
    if (dart.library.js_interop) 'captain_reachability_web.dart';

typedef ReachabilityProbe = Future<bool> Function();

class CaptainConnectivityWatcher extends ValueNotifier<bool> {
  CaptainConnectivityWatcher({
    ReachabilityProbe? probe,
    Stream<List<ConnectivityResult>>? interfaceChanges,
    this.offlineRecheck = const Duration(seconds: 10),
    this.onlineRecheck = const Duration(minutes: 1),
    this.confirmDelay = const Duration(seconds: 2),
  }) : _probe = probe ?? reachBackend,
       _interfaceChanges =
           interfaceChanges ?? Connectivity().onConnectivityChanged,
       super(false);

  final ReachabilityProbe _probe;
  final Stream<List<ConnectivityResult>> _interfaceChanges;

  final Duration offlineRecheck;

  final Duration onlineRecheck;

  final Duration confirmDelay;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _disposed = false;

  int _generation = 0;

  void start() {
    _subscription = _interfaceChanges.listen((_) => recheck());
    recheck();
  }

  void recheck() {
    if (_disposed) return;
    _timer?.cancel();
    final generation = ++_generation;
    unawaited(_evaluate(generation));
  }

  Future<void> _evaluate(int generation) async {
    var reachable = await _probe();
    if (!reachable) {
      await Future<void>.delayed(confirmDelay);
      if (_isStale(generation)) return;
      reachable = await _probe();
    }
    if (_isStale(generation)) return;

    value = !reachable;
    _timer = Timer(value ? offlineRecheck : onlineRecheck, recheck);
  }

  bool _isStale(int generation) => _disposed || generation != _generation;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  static Future<bool> reachBackend() async {
    final host = Uri.tryParse(AppFlavorConfig.current.supabaseUrl)?.host ?? '';
    if (host.isEmpty) return true;
    return probeHost(host);
  }
}
