import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/auth_method.dart';
import 'apple_auth_button.dart';
import 'auth_divider.dart';
import 'google_auth_button.dart';
import 'phone_auth_button.dart';

/// The "or continue with" block: a divider, then the alternative sign-in
/// methods, then one honest line when none of them is switched on yet.
///
/// Always *below* the working call to action, never above it. The hierarchy is
/// the point — email and password is the method that works today, and a screen
/// that opens with three providers the rider cannot use would be advertising
/// its own gaps. The divider is what says "everything under here is an
/// alternative".
///
/// [compact] picks the density: tiles on the welcome screen, where the hero and
/// three primary actions already own the fold, and full-width rows on the
/// sign-in and sign-up forms, which scroll and where the row form is what
/// riders recognise from every other app.
class AuthAlternativeMethods extends StatelessWidget {
  const AuthAlternativeMethods({
    super.key,
    this.methods = const [
      AuthMethod.google,
      AuthMethod.apple,
      AuthMethod.phoneOtp,
    ],
    this.compact = false,
  });

  final List<AuthMethod> methods;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthDivider(label: l10n.auth_or),
        const SizedBox(height: ClientSpacing.md),
        if (compact) _tiles() else _rows(),
        // Only claimed while it is true. The moment a provider is switched on,
        // this collapses on its own rather than lingering as a stale promise.
        if (methods.every((method) => !method.isAvailable)) ...[
          const SizedBox(height: ClientSpacing.sm),
          Text(
            l10n.auth_alternativeMethodsPendingNote,
            textAlign: TextAlign.center,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ],
      ],
    );
  }

  Widget _rows() {
    final buttons = <Widget>[];
    for (final method in methods) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: ClientSpacing.sm));
      }
      buttons.add(_buttonFor(method, compact: false));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
    );
  }

  /// Equal-width tiles across one row.
  ///
  /// [Expanded] rather than a measured width: the welcome screen lays this out
  /// inside an [IntrinsicHeight] (that is what lets its `Spacer`s distribute
  /// the fold), and an intrinsic pass cannot run a [LayoutBuilder] — a builder
  /// here throws "LayoutBuilder does not support returning intrinsic
  /// dimensions" and takes the whole screen down with it. A plain [Row] has
  /// intrinsics, so it survives the pass.
  Widget _tiles() {
    final children = <Widget>[];
    for (final method in methods) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: ClientSpacing.sm));
      }
      children.add(Expanded(child: _buttonFor(method, compact: true)));
    }
    // No `CrossAxisAlignment.stretch`: the parent column already stretches, so
    // this row has no bounded height to stretch into and would demand an
    // infinite one. The tiles carry their own 52pt minimum instead.
    return Row(children: children);
  }

  Widget _buttonFor(AuthMethod method, {required bool compact}) =>
      switch (method) {
        AuthMethod.google => GoogleAuthButton(compact: compact),
        AuthMethod.apple => AppleAuthButton(compact: compact),
        AuthMethod.phoneOtp => PhoneAuthButton(compact: compact),
      };
}
