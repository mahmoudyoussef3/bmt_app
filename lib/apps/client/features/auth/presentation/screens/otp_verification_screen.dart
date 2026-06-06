import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/widgets/app_spacing.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_state.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/otp_input_row.dart';

/// Six-digit OTP entry with resend timer and status banners (UI only).
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 59;
  Timer? _timer;
  bool _canResend = false;

  String get _displayPhone => widget.phoneNumber ?? '+20 10 1234 5678';

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _resendSeconds = 59;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        setState(() {
          _resendSeconds = 0;
          _canResend = true;
        });
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onOtpFilled() {
    context.read<ClientAuthCubit>().verifyOtp(
      phone: _displayPhone,
      code: _code,
    );
  }

  void _clearOtp() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    context.read<ClientAuthCubit>().resetOtpInput();
  }

  void _onResend() {
    if (!_canResend) return;
    _clearOtp();
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New code sent (placeholder)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<ClientAuthCubit, ClientAuthState>(
      listenWhen: (previous, current) =>
          previous.otpStatus != current.otpStatus,
      listener: (context, state) {
        if (state.otpStatus == AuthSubmissionStatus.success) {
          final navigator = Navigator.of(context);
          Future<void>.delayed(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            navigator.pushReplacementNamed(
              AuthRoutes.registration,
              arguments: {'phone': _displayPhone},
            );
          });
        }
      },
      builder: (context, authState) {
        final hasError = authState.otpStatus == AuthSubmissionStatus.failure;
        final isSuccess = authState.otpStatus == AuthSubmissionStatus.success;

        return AuthScaffold(
          title: 'Verify your number',
          subtitle: 'Enter the 6-digit code sent to $_displayPhone',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isSuccess)
                const OtpStatusBanner.success(
                  message: 'Code accepted — finishing sign in…',
                ),
              if (hasError) ...[
                OtpStatusBanner.error(
                  message:
                      authState.otpError ??
                      'Invalid code. Please try again or request a new code.',
                ),
                AppSpacing.hMd,
              ],
              OtpInputRow(
                controllers: _controllers,
                focusNodes: _focusNodes,
                hasError: hasError,
                enabled: !isSuccess,
                onCompleted: _onOtpFilled,
              ),
              AppSpacing.hMd,
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit phone number'),
                style: TextButton.styleFrom(foregroundColor: scheme.primary),
              ),
              AppSpacing.hSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code?",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(180),
                    ),
                  ),
                  TextButton(
                    onPressed: _canResend ? _onResend : null,
                    child: Text(
                      _canResend
                          ? 'Resend code'
                          : 'Resend in 0:${_resendSeconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _canResend
                            ? scheme.primary
                            : scheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ),
                ],
              ),
              if (hasError) ...[
                AppSpacing.hMd,
                AuthPrimaryButton(
                  label: 'Try again',
                  outline: true,
                  onPressed: _clearOtp,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
