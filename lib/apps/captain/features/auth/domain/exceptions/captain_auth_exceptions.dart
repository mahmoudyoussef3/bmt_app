/// Thrown when a phone number has no matching active driver — the caller
/// should route to the "request access" onboarding flow instead of retrying.
class CaptainPhoneNotRegisteredException implements Exception {}
