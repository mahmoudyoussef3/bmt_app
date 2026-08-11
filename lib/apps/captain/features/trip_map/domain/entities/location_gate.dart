enum LocationGate { ready, serviceDisabled, denied, deniedForever }

extension LocationGateX on LocationGate {
  bool get isReady => this == LocationGate.ready;
}
