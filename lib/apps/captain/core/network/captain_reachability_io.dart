import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Opens a short-lived TCP connection to [host] on 443.
///
/// A DNS lookup would be cheaper but the OS resolver can answer one from cache
/// with no network at all; a connection cannot be faked that way.
Future<bool> probeHost(String host) async {
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
