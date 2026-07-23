import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import 'forgot_password_link.dart';
import 'remember_me_checkbox.dart';

/// Remember-me and forgot-password on one line under the password field, where
/// both belong to the credentials the rider just typed. They used to stack as
/// two full-width rows, which pushed the sign-in button below the fold.
///
/// A [Wrap] rather than a [Row]: at a large system font the two labels no
/// longer fit across a small phone, and stacking them is the only readable
/// answer — a squeezed row would ellipsize "Forgot password?" into a link
/// nobody can act on.
class SignInOptionsRow extends StatelessWidget {
  const SignInOptionsRow({
    super.key,
    required this.isLoading,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotPassword,
  });

  final bool isLoading;
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RememberMeCheckbox(
          value: rememberMe,
          label: context.l10n.auth_rememberMe,
          onChanged: isLoading ? (_) {} : onRememberChanged,
        ),
        ForgotPasswordLink(onPressed: isLoading ? null : onForgotPassword),
      ],
    );
  }
}
