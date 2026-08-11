import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../auth_field_decoration.dart';
import '../auth_validators.dart';

/// The phone input: a fixed country block, then the national number.
///
/// EasyWay operates in Egypt only, so the country is shown rather than picked —
/// a country list would be a scroll through 200 entries to land back on the one
/// value that is ever correct. When a second country is added this becomes a
/// tappable prefix and nothing else on the screen moves.
///
/// ## The two directional traps
///
/// The prefix block sits at the *start* of the field, which under Arabic RTL is
/// the right — hence [EdgeInsetsDirectional] and no `Row` with a hard-coded
/// left. But the number itself is typed and read left-to-right even in Arabic,
/// so the input is pinned to [TextDirection.ltr]; letting it inherit RTL puts
/// the digits in an order no rider recognises as their own number.
class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      textDirection: TextDirection.ltr,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      onFieldSubmitted: onSubmitted,
      validator: (value) => AuthValidators.phone(value, l10n),
      inputFormatters: [
        
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      cursorColor: ClientColors.primaryFor(context),
      style: ClientTypography.bodyMedium(context).copyWith(
        color: ClientColors.textPrimaryFor(context),
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      decoration:
          authFieldDecoration(
            context: context,
            label: l10n.auth_phoneNumber,
            icon: Icons.phone_outlined,
          ).copyWith(
            hintText: '10 1234 5678',
            hintStyle: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
            hintTextDirection: TextDirection.ltr,
            prefixIcon: const _CountryPrefix(),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
    );
  }
}

/// The immovable `🇪🇬 +20` block at the start of the field.
class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        ClientSpacing.md,
        0,
        ClientSpacing.sm,
        0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🇪🇬', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '+20',
            textDirection: TextDirection.ltr,
            style: ClientTypography.bodyMedium(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: ClientSpacing.sm),
          SizedBox(
            height: 22,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: ClientColors.borderFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
