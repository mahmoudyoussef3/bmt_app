/// Web has no raw sockets, so the probe cannot be run.
///
/// Reports reachable rather than offline: the watcher's whole contract is that
/// it only ever accuses the network on proof, and "this platform cannot check"
/// is not proof. The captain app ships to phones; this exists so the package
/// still compiles for web tooling.
Future<bool> probeHost(String host) async => true;
