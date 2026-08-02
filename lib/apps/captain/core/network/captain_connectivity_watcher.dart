import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/flavors/app_flavor.dart';

/// A probe that answers "can this phone reach the backend right now?".
typedef ReachabilityProbe = Future<bool> Function();

/// Tracks whether the captain's phone is *actually* cut off, exposed as
/// `value == true` meaning "confirmed offline".
///
/// `connectivity_plus` on its own cannot answer that. It reports which network
/// *interfaces* the OS has, and it reports them as a stream of **changes**, so
/// a single wrong reading is never corrected: nothing has changed since, so no
/// further event is emitted. Both platforms produce such readings on a phone
/// that is perfectly online — Android's default-network callback reports
/// `none` while the default network is handed from Wi-Fi to mobile data (and
/// for any network whose capabilities momentarily lack `INTERNET`), and iOS
/// returns `none` from `NWPathMonitor.currentPath` until its first path update
/// lands, which is after a cold start's first read. A screen that trusted that
/// reading latched "no internet" on a captain who had internet all trip.
///
/// So the interface reading is demoted to a hint about *when* to look, and the
/// verdict comes from actually opening a socket to the backend. On top of that
/// nothing is allowed to latch: the watcher re-checks on a timer, and the UI
/// re-checks it on app resume. That also buys the honest opposite case — a bus
/// Wi-Fi that is associated but carries no traffic reads as offline, which is
/// what the captain experiences.
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

  /// How soon to look again while showing the banner. Short, because this is
  /// the recovery path: it is what stops a wrong reading from sticking.
  final Duration offlineRecheck;

  /// How often to look again while online — cheap enough to run all trip, and
  /// the only thing that catches a connection that dies without the interface
  /// ever dropping.
  final Duration onlineRecheck;

  /// The gap before a failed probe is retried. One dropped socket is not an
  /// outage.
  final Duration confirmDelay;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _disposed = false;

  /// Identifies the current evaluation, so a newer one supersedes whatever is
  /// still in flight instead of racing it to `value`.
  int _generation = 0;

  void start() {
    _subscription = _interfaceChanges.listen((_) => recheck());
    recheck();
  }

  /// Re-evaluates now: on start, on any interface change, on app resume, and
  /// on the recurring timer.
  void recheck() {
    if (_disposed) return;
    _timer?.cancel();
    final generation = ++_generation;
    unawaited(_evaluate(generation));
  }

  Future<void> _evaluate(int generation) async {
    var reachable = await _probe();
    if (!reachable) {
      // A captain crossing between towers loses a socket for a second at a
      // time. Only a failure that survives a second attempt reaches the screen.
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

  /// Opens a short-lived TCP connection to the backend host.
  ///
  /// A DNS lookup would be cheaper but the OS resolver can answer one from
  /// cache with no network at all; a connection cannot be faked that way.
  static Future<bool> reachBackend() async {
    final host = Uri.tryParse(AppFlavorConfig.current.supabaseUrl)?.host ?? '';
    // Nothing to probe means nothing is proven — never accuse the network on
    // a guess.
    if (host.isEmpty) return true;

    try {
      final socket = await Socket.connect(
        host,
        443,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (error) {
      // Anything else (a platform restriction, a plugin fault) says nothing
      // about the captain's connection, so it must not read as an outage.
      if (kDebugMode) debugPrint('🌐 [CAPTAIN REACHABILITY] $error');
      return true;
    }
  }
}
