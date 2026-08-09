import '../../domain/entities/auth_method.dart';
import '../../domain/entities/social_auth_result.dart';

/// The provider payload behind a [SocialAuthResult].
///
/// One model covers Google, Apple *and* phone/OTP rather than three
/// near-identical files. Every one of those methods reaches this app the same
/// way — Supabase completes the exchange and returns a `User` whose
/// `userMetadata` carries whatever the provider was willing to share — so the
/// only thing that differs between them is which keys are populated, and that
/// is data, not structure. Splitting it would give three classes with the same
/// fields and one shared parser, which is the duplication the architecture is
/// meant to avoid.
///
/// [fromAuthUser] is written against the shape Supabase's `User` serialises to
/// rather than against the SDK type, so nothing in `data/models` has to import
/// the client library and the parser stays unit-testable from a plain map.
class SocialAuthResultModel {
  const SocialAuthResultModel({
    required this.method,
    required this.userId,
    required this.isNewAccount,
    this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  /// Builds from a Supabase auth user map.
  ///
  /// Providers disagree on metadata keys for the same fact — Google sends
  /// `name` and `picture`, Apple sends `full_name` and usually nothing else —
  /// so each field reads the alternatives in turn instead of assuming one.
  factory SocialAuthResultModel.fromAuthUser(
    Map<String, dynamic> user, {
    required AuthMethod method,
    bool isNewAccount = false,
  }) {
    final metadata = switch (user['user_metadata']) {
      final Map<String, dynamic> map => map,
      final Map map => map.cast<String, dynamic>(),
      _ => const <String, dynamic>{},
    };

    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = metadata[key] ?? user[key];
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
      return null;
    }

    return SocialAuthResultModel(
      method: method,
      userId: user['id']?.toString() ?? '',
      isNewAccount: isNewAccount,
      email: pick(const ['email']),
      fullName: pick(const ['full_name', 'name', 'display_name']),
      phone: pick(const ['phone', 'phone_number']),
      avatarUrl: pick(const ['avatar_url', 'picture']),
    );
  }

  final AuthMethod method;
  final String userId;
  final bool isNewAccount;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  SocialAuthResult toEntity() => SocialAuthResult(
    method: method,
    userId: userId,
    isNewAccount: isNewAccount,
    email: email,
    fullName: fullName,
    phone: phone,
    avatarUrl: avatarUrl,
  );
}
