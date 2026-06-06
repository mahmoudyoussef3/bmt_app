sealed class IncidentState {
  const IncidentState();
}

class IncidentReady extends IncidentState {
  const IncidentReady({this.submitted = false});

  final bool submitted;
}

class IncidentSubmitting extends IncidentState {
  const IncidentSubmitting();
}

class IncidentError extends IncidentState {
  const IncidentError(this.message);

  final String message;
}
