import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../cubit/captain_auth_cubit.dart';
import '../widgets/captain_auth_error_banner.dart';
import '../widgets/captain_auth_field.dart';
import '../widgets/captain_auth_header.dart';
import '../widgets/captain_auth_reveal.dart';
import '../widgets/captain_auth_scaffold.dart';
import '../widgets/captain_remember_me_checkbox.dart';

class CaptainLoginScreen extends StatefulWidget {
  const CaptainLoginScreen({super.key, this.onRequestAccess});

  /// When provided (by the auth gate), tapping "Request access" swaps the
  /// top-level screen to the onboarding flow instead of pushing a route.
  final VoidCallback? onRequestAccess;

  @override
  State<CaptainLoginScreen> createState() => _CaptainLoginScreenState();
}

class _CaptainLoginScreenState extends State<CaptainLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _prefillRememberedPhone();
  }

  Future<void> _prefillRememberedPhone() async {
    final phone = await context.read<CaptainAuthCubit>().loadRememberedPhone();
    if (!mounted || phone == null) return;
    setState(() {
      _phoneCtrl.text = phone;
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CaptainAuthCubit>().signIn(
      phone: _phoneCtrl.text.trim(),
      rememberMe: _rememberMe,
    );
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length < 10 ? 'أدخل رقم هاتف صحيح' : null;
  }

  void _openRequestAccess() {
    final swap = widget.onRequestAccess;
    if (swap != null) {
      swap();
      return;
    }
    context.openRequestAccess();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CaptainAuthCubit>();

    return BlocBuilder<CaptainAuthCubit, CaptainAuthState>(
      builder: (context, state) {
        final loading = state is CaptainAuthLoading;
        final error = state is CaptainAuthError ? state.message : null;

        return AbsorbPointer(
          absorbing: loading,
          child: CaptainAuthScaffold(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CaptainAuthReveal(
                      child: CaptainAuthHeader(
                        title: 'تسجيل دخول الكابتن',
                        subtitle:
                            'أدخل رقم هاتفك المسجّل لعرض رحلاتك والبدء بالقيادة.',
                      ),
                    ),
                    const SizedBox(height: CaptainDesignTokens.s40),
                    CaptainAuthErrorBanner(
                      message: error,
                      onDismiss: cubit.resetError,
                    ),
                    CaptainAuthReveal(
                      order: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CaptainAuthField(
                            controller: _phoneCtrl,
                            label: 'رقم الهاتف',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            forceLtr: true,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            onSubmitted: (_) => _submit(),
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: CaptainDesignTokens.s8),
                          CaptainRememberMeCheckbox(
                            value: _rememberMe,
                            onChanged: loading
                                ? (_) {}
                                : (checked) =>
                                      setState(() => _rememberMe = checked),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: CaptainDesignTokens.s20),
                    CaptainAuthReveal(
                      order: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CaptainButton(
                            label: loading
                                ? 'جارٍ تسجيل الدخول...'
                                : 'تسجيل الدخول',
                            isLoading: loading,
                            onPressed: loading ? null : _submit,
                          ),
                          const SizedBox(height: CaptainDesignTokens.s24),
                          const _AuthDivider(),
                          const SizedBox(height: CaptainDesignTokens.s16),
                          _RequestAccessLink(
                            onTap: loading ? null : _openRequestAccess,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A hairline rule with a centred "أو" — separates signing in from the
/// distinct path of asking to join.
class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: CaptainColors.dividerFor(context), height: 1),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CaptainDesignTokens.s12,
          ),
          child: Text(
            'أو',
            style: CaptainTypography.labelSmall(
              context,
            ).copyWith(color: CaptainColors.textSecondaryFor(context)),
          ),
        ),
        line,
      ],
    );
  }
}

/// Entry point to onboarding for a captain who has no account yet.
///
/// Presented as a full tappable card rather than an inline text link: it is the
/// screen's only other route forward, and a captain who can't sign in because
/// they were never provisioned needs to find it without hunting.
class _RequestAccessLink extends StatelessWidget {
  const _RequestAccessLink({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CaptainCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s16,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s8),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(26),
              borderRadius: CaptainDesignTokens.br12,
            ),
            child: Icon(Icons.badge_outlined, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كابتن جديد؟',
                  style: CaptainTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: CaptainColors.textPrimaryFor(context),
                  ),
                ),
                Text(
                  'اطلب الانضمام وسيراجع فريق العمليات طلبك',
                  style: CaptainTypography.labelSmall(context).copyWith(
                    color: CaptainColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          DirectionalIcon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: CaptainColors.textSecondaryFor(context),
          ),
        ],
      ),
    );
  }
}
