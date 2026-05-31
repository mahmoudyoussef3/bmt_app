import 'dart:async';

/// Lightweight WebSocket / streaming scaffold for real-time updates.
/// In production replace the internals with the real WS client and auth.
class WebSocketService {
  final _controller = StreamController<dynamic>.broadcast();

  Stream<dynamic> get stream => _controller.stream;

  void connect() {
    // TODO: implement real WebSocket connection
  }

  void disconnect() {
    _controller.close();
  }

  /// For mocks and tests: push an event into the stream
  void pushEvent(dynamic event) {
    if (!_controller.isClosed) _controller.add(event);
  }
}
