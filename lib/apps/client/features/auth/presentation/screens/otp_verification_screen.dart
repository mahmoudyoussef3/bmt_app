import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../routes/otp_verification_arguments.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/phone_otp/otp_verification_form.dart';

/// Step two of signing in by SMS: the code itself.
///
/// Takes [args] rather than reading a cubit, because a named route cannot carry
/// one across the push — see [OtpVerificationArguments]. An invalid or missing
/// argument means the screen was reached out of order (a stale deep link, a
/// restored stack), and the honest answer is to unwind to the number rather
/// than draw six boxes for a code that was never sent.
class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key, required this.args});

  final OtpVerificationArguments args;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: context.l10n.auth_otpTitle,
      child: OtpVerificationForm(args: args),
    );
  }
}
