sealed class CaptainActivationState {
  const CaptainActivationState();
}

/// Trying to exchange the local session for an operational (Supabase) session.
class CaptainActivationChecking extends CaptainActivationState {
  const CaptainActivationChecking();
}

/// The captain is approved, but operations has not activated their driver
/// record yet — nothing to sign in to. Keep waiting, keep polling.
class CaptainActivationAwaiting extends CaptainActivationState {
  const CaptainActivationAwaiting();
}

/// An operational session now exists; the auth gate takes over from here.
class CaptainActivationActivated extends CaptainActivationState {
  const CaptainActivationActivated();
}

class CaptainActivationFailed extends CaptainActivationState {
  const CaptainActivationFailed(this.message);

  final String message;
}
