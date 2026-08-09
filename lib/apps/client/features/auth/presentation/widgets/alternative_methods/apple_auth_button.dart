import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/auth_method.dart';
import '../../cubit/social_auth_cubit.dart';
import '../../cubit/social_auth_state.dart';
import 'social_auth_button.dart';

/// "Continue with Apple".
///
/// Same inert-until-available contract as [GoogleAuthButton]. Unlike Google's
/// mark, Apple's glyph *is* meant to take the surface's foreground colour, so
/// it follows [ClientColors.textPrimaryFor] into dark mode instead of being
/// pinned to black.
class AppleAuthButton extends StatelessWidget {
  const AppleAuthButton({super.key, this.compact = false});

  static const _method = AuthMethod.apple;

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
      label: context.l10n.auth_continueWithApple,
      compactLabel: 'Apple',
      glyph: Icon(
        Icons.apple,
        size: 22,
        color: ClientColors.textPrimaryFor(context),
      ),
      compact: compact,
      isAvailable: _method.isAvailable,
      isLoading: isLoading,
      onPressed: _method.isAvailable
          ? () => context.read<SocialAuthCubit>().signInWithApple()
          : null,
    );
  }
}
