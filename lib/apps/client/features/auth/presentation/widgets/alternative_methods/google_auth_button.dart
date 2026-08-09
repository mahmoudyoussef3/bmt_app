import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/auth_method.dart';
import '../../cubit/social_auth_cubit.dart';
import '../../cubit/social_auth_state.dart';
import 'google_g_logo.dart';
import 'social_auth_button.dart';

/// "Continue with Google".
///
/// While [AuthMethod.google] is unavailable this renders as a plain, inert
/// [SocialAuthButton] and never touches a [SocialAuthCubit] — no `BlocBuilder`
/// is inserted, so the widget can sit on a screen that provides no such cubit.
/// That is what lets it ship on the welcome screen today. Flipping the flag
/// switches on the spinner wiring below; nothing here has to be rewritten.
class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({super.key, this.compact = false});

  static const _method = AuthMethod.google;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!_method.isAvailable) return _button(context, isLoading: false);

    return BlocBuilder<SocialAuthCubit, SocialAuthState>(
      buildWhen: (previous, current) =>
          previous.isLoadingMethod(_method) != current.isLoadingMethod(_method),
      builder: (context, state) =>
          _button(context, isLoading: state.isLoadingMethod(_method)),
    );
  }

  Widget _button(BuildContext context, {required bool isLoading}) {
    return SocialAuthButton(
      label: context.l10n.auth_continueWithGoogle,
      compactLabel: 'Google',
      glyph: const GoogleGLogo(size: 20),
      compact: compact,
      isAvailable: _method.isAvailable,
      isLoading: isLoading,
      onPressed: _method.isAvailable
          ? () => context.read<SocialAuthCubit>().signInWithGoogle()
          : null,
    );
  }
}
