import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The two ways out of a code that never arrived: wait for a resend, or go back
/// and fix the number.
///
/// ## What runs today
///
/// [secondsRemaining] is a value this widget renders, never one it counts. No
/// ticker is started here — the countdown is deliberately static in this build,
/// and `OtpChallenge.secondsUntilResendAt` is the function that will feed it
/// once codes are really sent. Driving it from an absolute instant, rather than
/// from a local timer, is what will keep it correct across a backgrounded app.
class OtpResendRow extends StatelessWidget {
  const OtpResendRow({
    super.key,
    required this.secondsRemaining,
    required this.onResend,
    required this.onChangeNumber,
  });

  /// `0` means a resend is allowed; anything higher renders the wait instead.
  final int secondsRemaining;

  /// `null` leaves the resend inert — which is the case in this build.
  final VoidCallback? onResend;

  final VoidCallback onChangeNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canResend = secondsRemaining <= 0 && onResend != null;

    return Column(
      children: [
        if (canResend)
          ClientButton.text(label: l10n.auth_resendCode, onPressed: onResend)
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: ClientColors.textTertiaryFor(context),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.auth_resendCodeIn(_formatted(secondsRemaining)),
                  textAlign: TextAlign.center,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
              ),
            ],
          ),
        const SizedBox(height: ClientSpacing.xxs),
        ClientButton.text(
          label: l10n.auth_changePhoneNumber,
          onPressed: onChangeNumber,
        ),
      ],
    );
  }

  /// `mm:ss`, forced LTR by construction rather than by direction: the digits
  /// are assembled here and the caller renders them inside an Arabic line, so
  /// the only safe form is one with no reorderable characters in it.
  String _formatted(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final remainder = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}
