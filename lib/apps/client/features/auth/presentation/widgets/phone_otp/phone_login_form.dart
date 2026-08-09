import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/validation/contact_validation.dart';

import '../../../domain/entities/auth_method.dart';
import '../../routes/auth_routes.dart';
import '../../routes/otp_verification_arguments.dart';
import '../alternative_methods/coming_soon_badge.dart';
import '../alternative_methods/social_auth_error_banner.dart';
import '../auth_info_card.dart';
import '../auth_section_card.dart';
import '../auth_security_note.dart';
import 'phone_number_field.dart';

/// The phone-number step of the OTP flow.
///
/// Owns its controller and form key — the same arrangement [SignInForm] uses,
/// and the only place either can be disposed.
///
/// ## What runs today
///
/// The form validates locally and nothing else. No code is requested, because
/// [AuthMethod.phoneOtp] is off: the submit button is inert and carries a
/// [ComingSoonBadge] instead of a spinner. Everything the live version needs is
/// already here — the normalised number, the validation, the arguments the OTP
/// screen expects — so switching it on means replacing [_submit]'s navigation
/// with `context.read<SocialAuthCubit>().sendOtp(...)` and letting the listener
/// push on `otpSent`.
class PhoneLoginForm extends StatefulWidget {
  const PhoneLoginForm({super.key});

  @override
  State<PhoneLoginForm> createState() => _PhoneLoginFormState();
}

class _PhoneLoginFormState extends State<PhoneLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pushNamed(
      AuthRoutes.otpVerification,
      // Built through the arguments class rather than a raw map, so the pusher
      // and the screen cannot disagree about the key names.
      arguments: OtpVerificationArguments(
        phone: ContactValidation.normalizeEgyptianPhone(_phoneController.text),
      ).toArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAvailable = AuthMethod.phoneOtp.isAvailable;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SocialAuthErrorBanner(),
            AuthSectionCard(
              children: [
                PhoneNumberField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  onSubmitted: isAvailable ? (_) => _submit() : null,
                ),
                const SizedBox(height: ClientSpacing.sm),
                AuthInfoCard(
                  icon: Icons.sms_outlined,
                  text: l10n.auth_phoneOtpHelper,
                ),
              ],
            ),
            const SizedBox(height: ClientSpacing.lg),
            ClientButton(
              label: l10n.auth_sendOtpCode,
              onPressed: isAvailable ? _submit : null,
              icon: isAvailable
                  ? null
                  : const Icon(Icons.lock_clock_outlined, size: 18),
            ),
            if (!isAvailable) ...[
              const SizedBox(height: ClientSpacing.sm),
              const Center(child: ComingSoonBadge()),
            ],
            const SizedBox(height: ClientSpacing.sm),
            AuthSecurityNote(text: l10n.auth_phoneOtpSecurityNote),
          ],
        ),
      ),
    );
  }
}
