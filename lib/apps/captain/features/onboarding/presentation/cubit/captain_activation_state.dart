sealed class CaptainActivationState {
  const CaptainActivationState();
}

class CaptainActivationChecking extends CaptainActivationState {
  const CaptainActivationChecking();
}

class CaptainActivationAwaiting extends CaptainActivationState {
  const CaptainActivationAwaiting();
}

class CaptainActivationActivated extends CaptainActivationState {
  const CaptainActivationActivated();
}

class CaptainActivationFailed extends CaptainActivationState {
  const CaptainActivationFailed(this.message);

  final String message;
}
