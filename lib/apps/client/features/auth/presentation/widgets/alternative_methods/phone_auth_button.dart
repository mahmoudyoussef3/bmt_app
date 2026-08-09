import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/auth_method.dart';
import '../../routes/auth_routes.dart';
import 'social_auth_button.dart';

/// "Sign in with your phone number".
///
/// The odd one out of the three: it opens a screen this app owns rather than a
/// provider sheet, so it never touches [SocialAuthCubit] — it only navigates,
/// and the phone screen scopes its own cubit. That also means it is the one
/// alternative method that could be switched on purely client-side, which is
/// why the flag it reads is [AuthMethod.phoneOtp] and not a navigation
/// condition invented here: the entry point and the screens behind it turn on
/// together or not at all.
class PhoneAuthButton extends StatelessWidget {
  const PhoneAuthButton({super.key, this.compact = false});

  static const _method = AuthMethod.phoneOtp;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SocialAuthButton(
      label: l10n.auth_continueWithPhone,
      compactLabel: l10n.auth_phoneShort,
      glyph: Icon(
        Icons.phone_iphone_rounded,
        size: 21,
        color: ClientColors.primaryFor(context),
      ),
      compact: compact,
      isAvailable: _method.isAvailable,
      onPressed: _method.isAvailable
          ? () => Navigator.of(context).pushNamed(AuthRoutes.phoneLogin)
          : null,
    );
  }
}
