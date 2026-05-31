import 'dart:async';
import '../network/websocket_service.dart';
import '../../domain/models/trip_event.dart';

class LiveEventBus {
  final WebSocketService ws;
  final StreamController<TripEvent> _controller = StreamController<TripEvent>.broadcast();

  LiveEventBus(this.ws) {
    // Forward events from WebSocketService into the typed event stream
    ws.stream.listen((event) {
      if (event is TripEvent) _controller.add(event);
    });
  }

  Stream<TripEvent> get stream => _controller.stream;

  void emit(TripEvent event) {
    _controller.add(event);
    // Also push into ws so other systems can get it
    ws.pushEvent(event);
  }
}
