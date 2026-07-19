/// Named routes for the Client App communication hub.
class CommunicationRoutes {
  CommunicationRoutes._();

  static const communication = '/communication';

  /// One open conversation, pushed over [communication].
  static const chatThread = '/communication/thread';
}
