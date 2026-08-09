import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/auth_method.dart';
import '../../routes/otp_verification_arguments.dart';
import '../alternative_methods/coming_soon_badge.dart';
import '../alternative_methods/social_auth_error_banner.dart';
import '../auth_section_card.dart';
import 'otp_code_field.dart';
import 'otp_resend_row.dart';

/// The code-entry step: six boxes, a way to ask for another code, and a way
/// back to the number.
///
/// ## What runs today
///
/// Nothing is verified. [AuthMethod.phoneOtp] is off, so the confirm button is
/// inert, the resend is inert, and the countdown renders
/// [OtpVerificationArguments.resendAfterSeconds] as a fixed value instead of
/// ticking. The rider can still type — the boxes fill, autofill works, the
/// completed-code callback fires — because a code field that will not accept
/// digits is not a preview of anything.
///
/// Switching it on: give [OtpCodeField.onCompleted] and the button
/// `context.read<SocialAuthCubit>().verifyOtp(code)`, drive [hasError] from
/// `SocialAuthState.failure`, and replace the fixed countdown with
/// `OtpChallenge.secondsUntilResendAt` on a one-second ticker.
class OtpVerificationForm extends StatefulWidget {
  const OtpVerificationForm({super.key, required this.args});

  final OtpVerificationArguments args;

  @override
  State<OtpVerificationForm> createState() => _OtpVerificationFormState();
}

class _OtpVerificationFormState extends State<OtpVerificationForm> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAvailable = AuthMethod.phoneOtp.isAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SentToHeader(args: widget.args),
        const SizedBox(height: ClientSpacing.lg),
        const SocialAuthErrorBanner(),
        AuthSectionCard(
          children: [
            OtpCodeField(
              controller: _codeController,
              length: widget.args.codeLength,
              enabled: true,
            ),
          ],
        ),
        const SizedBox(height: ClientSpacing.lg),
        ClientButton(
          label: l10n.auth_verifyCode,
          onPressed: isAvailable ? () {} : null,
          icon: isAvailable
              ? null
              : const Icon(Icons.lock_clock_outlined, size: 18),
        ),
        if (!isAvailable) ...[
          const SizedBox(height: ClientSpacing.sm),
          const Center(child: ComingSoonBadge()),
        ],
        const SizedBox(height: ClientSpacing.md),
        OtpResendRow(
          secondsRemaining: widget.args.resendAfterSeconds,
          onResend: isAvailable ? () {} : null,
          onChangeNumber: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// "We sent a 6-digit code to" over the number itself.
///
/// The number gets its own line under a [TextDirection.ltr] rather than being
/// interpolated into the Arabic sentence: inside RTL text the bidi algorithm
/// moves the leading `+` to the far end, and a rider shown `20+ …` cannot tell
/// whether the code went to the right phone.
class _SentToHeader extends StatelessWidget {
  const _SentToHeader({required this.args});

  final OtpVerificationArguments args;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ClientColors.primaryContainerFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.lg),
          ),
          child: Icon(
            Icons.sms_outlined,
            size: 28,
            color: ClientColors.onPrimaryContainerFor(context),
          ),
        ),
        const SizedBox(height: ClientSpacing.md),
        Text(
          l10n.auth_otpIntro(args.codeLength),
          textAlign: TextAlign.center,
          style: ClientTypography.bodyMedium(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: ClientSpacing.xxs),
        Text(
          args.displayPhone,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: ClientTypography.labelLarge(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
      ],
    );
  }
}
