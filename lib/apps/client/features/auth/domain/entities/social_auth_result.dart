import 'auth_method.dart';

/// What an alternative sign-in hands back once the provider has authenticated
/// the rider and the session exists.
///
/// The same shape serves Google, Apple and phone/OTP: whichever provider ran,
/// the app afterwards needs the same four things — who signed in, which method
/// they used, what profile fields the provider was willing to share, and
/// whether a `clients` row has to be created for them.
///
/// The provider's tokens are deliberately absent. Supabase owns the session
/// (see `SupabaseClientAuthDatasource`), so a token on this entity would be a
/// second, staler copy of the truth that presentation code could reach for.
class SocialAuthResult {
  const SocialAuthResult({
    required this.method,
    required this.userId,
    required this.isNewAccount,
    this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  /// Which method produced this session.
  final AuthMethod method;

  /// The Supabase auth user id the session belongs to.
  final String userId;

  /// `true` when the provider authenticated someone with no `clients` row yet,
  /// so the app must complete their profile before dropping them on home.
  ///
  /// Apple in particular hands over a name exactly once — on first consent —
  /// so the caller that ignores this flag can never ask for it again.
  final bool isNewAccount;

  /// Apple relay addresses and phone sign-ins may carry no email at all.
  final String? email;

  final String? fullName;

  /// Present for phone/OTP; usually absent for Google and Apple.
  final String? phone;

  final String? avatarUrl;

  /// Whether the app still has to collect profile fields the provider withheld.
  /// EasyWay books seats against a name and a phone number, so a session
  /// missing either cannot go straight to booking.
  bool get needsProfileCompletion =>
      isNewAccount || (fullName?.isEmpty ?? true) || (phone?.isEmpty ?? true);
}
