import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_digits.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_input_formatters.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_validators.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../cubit/captain_auth_cubit.dart';
import '../widgets/captain_auth_error_banner.dart';
import '../widgets/captain_auth_field.dart';
import '../widgets/captain_auth_hero.dart';
import '../widgets/captain_auth_reveal.dart';
import '../widgets/captain_auth_scaffold.dart';
import '../widgets/captain_remember_me_checkbox.dart';

class CaptainLoginScreen extends StatefulWidget {
  const CaptainLoginScreen({super.key, this.onRequestAccess});

  final VoidCallback? onRequestAccess;

  @override
  State<CaptainLoginScreen> createState() => _CaptainLoginScreenState();
}

class _CaptainLoginScreenState extends State<CaptainLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _phoneNode = FocusNode();

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
      // Normalized on the way in as well as out: input formatters do not run on
      // a programmatic set, so a value remembered before the field enforced
      // digits would otherwise come back with its separators intact and fail
      // validation the captain cannot see the cause of.
      _phoneCtrl.text = CaptainDigits.only(phone);
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneNode.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.selectionClick();
    // Only the digits go to the RPC: a number pasted from a contact card
    // arrives with spaces, and the lookup matches on the stored string.
    context.read<CaptainAuthCubit>().signIn(
      phone: CaptainDigits.only(_phoneCtrl.text),
      rememberMe: _rememberMe,
    );
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
            hero: const CaptainAuthReveal(
              child: CaptainAuthHero(
                badge: 'تطبيق الكباتن',
                title: 'تسجيل دخول الكابتن',
                subtitle: 'أدخل رقم هاتفك المسجّل لعرض رحلاتك والبدء بالقيادة.',
              ),
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CaptainAuthErrorBanner(
                      message: error,
                      onDismiss: cubit.resetError,
                    ),
                    CaptainAuthReveal(
                      order: 1,
                      child: CaptainCard(
                        elevated: true,
                        padding: const EdgeInsets.all(CaptainDesignTokens.s16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CaptainAuthField(
                              controller: _phoneCtrl,
                              focusNode: _phoneNode,
                              label: 'رقم الهاتف',
                              hint: '01xxxxxxxxx',
                              icon: Icons.phone_iphone_rounded,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              forceLtr: true,
                              enabled: !loading,
                              inputFormatters: const [
                                CaptainDigitsInputFormatter(maxLength: 11),
                              ],
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              onSubmitted: (_) => _submit(),
                              validator: CaptainValidators.phone,
                              helper: 'نفس الرقم المسجّل لدى مكتبك.',
                            ),
                            const SizedBox(height: CaptainDesignTokens.s12),
                            Divider(
                              height: 1,
                              color: CaptainColors.dividerFor(context),
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
                            icon: loading ? null : Icons.login_rounded,
                            isLoading: loading,
                            onPressed: loading ? null : _submit,
                          ),
                          const SizedBox(height: CaptainDesignTokens.s24),
                          const _AuthDivider(),
                          const SizedBox(height: CaptainDesignTokens.s16),
                          _RequestAccessLink(
                            onTap: loading ? null : _openRequestAccess,
                          ),
                          const SizedBox(height: CaptainDesignTokens.s20),
                          const _SupportNote(),
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

class _RequestAccessLink extends StatelessWidget {
  const _RequestAccessLink({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = CaptainColors.primaryInkFor(context);

    return CaptainCard(
      onTap: onTap,
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: CaptainDesignTokens.br12,
            ),
            child: Icon(Icons.badge_outlined, size: 20, color: accent),
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
                const SizedBox(height: 2),
                Text(
                  'اطلب الانضمام وسيراجع فريق العمليات طلبك',
                  style: CaptainTypography.labelSmall(context).copyWith(
                    color: CaptainColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
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

/// The way out of the one dead end this screen has: the captain's number is
/// right, they are not new, and sign-in still refuses. Only the office that
/// holds their record can fix that, so the screen says so instead of leaving
/// them retrying.
class _SupportNote extends StatelessWidget {
  const _SupportNote();

  @override
  Widget build(BuildContext context) {
    final muted = CaptainColors.textSecondaryFor(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.support_agent_rounded, size: 16, color: muted),
        const SizedBox(width: CaptainDesignTokens.s8),
        Flexible(
          child: Text(
            'مشكلة في الدخول؟ تواصل مع مكتبك',
            textAlign: TextAlign.center,
            style: CaptainTypography.bodySmall(
              context,
            ).copyWith(color: muted, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
