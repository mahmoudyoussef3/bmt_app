import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

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
    if (kDebugMode) debugPrint('🌐 [CAPTAIN REACHABILITY] $error');
    return true;
  }
}
