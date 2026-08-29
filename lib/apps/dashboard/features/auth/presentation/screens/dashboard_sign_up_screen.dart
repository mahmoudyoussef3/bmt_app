import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../cubit/dashboard_auth_cubit.dart';
import '../widgets/dashboard_auth_divider.dart';
import '../widgets/dashboard_auth_error_banner.dart';
import '../widgets/dashboard_auth_field.dart';
import '../widgets/dashboard_auth_layout.dart';
import '../widgets/dashboard_auth_theme_toggle.dart';

/// Self-service office registration: office name, email, password.
///
/// Sits in the same [DashboardAuthLayout] frame as the sign-in screen — the EWT
/// brand sweep on the leading side, the form beside it — because these are the
/// two halves of one front door, and a centred 440px column next to a
/// full-bleed gradient would read as a different product.
///
/// Deliberately three inputs and no more (the confirmation is a check on the
/// third, not a fourth answer). The login screen asks for a Name, but the
/// operator filling this form has not chosen one — the server derives it from
/// the email — and `resolve_office_user_login` accepts the email address
/// itself, so they sign in afterwards with exactly what they typed here.
///
/// The office this creates is workable immediately and invisible to passengers
/// until the platform publishes it, which is what the notice above the button
/// says out loud: an operator who is not told that will read an empty
/// marketplace as a broken product.
class DashboardSignUpScreen extends StatefulWidget {
  const DashboardSignUpScreen({super.key, required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  State<DashboardSignUpScreen> createState() => _DashboardSignUpScreenState();
}

class _DashboardSignUpScreenState extends State<DashboardSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  /// The last registration failure, held here rather than read off the cubit
  /// state: [DashboardAuthCubit.resetError] returns the cubit to signed-out as
  /// soon as the message has been taken, so the form stays interactive while
  /// the banner is still on screen. Same contract as the sign-in screen — and
  /// the same reason it is a banner and not a snackbar: "هذا البريد مسجل
  /// بالفعل" has to survive long enough to be acted on.
  String? _error;

  @override
  void dispose() {
    _officeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<DashboardAuthCubit>().signUp(
      email: _emailCtrl.text.trim().toLowerCase(),
      password: _passCtrl.text,
      officeName: _officeCtrl.text.trim(),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'أدخل البريد الإلكتروني';

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$').hasMatch(email);
    return valid ? null : 'البريد الإلكتروني غير صالح';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<DashboardAuthCubit, DashboardAuthState>(
        listener: (context, state) {
          if (state is DashboardAuthError) {
            setState(() => _error = state.message);
            context.read<DashboardAuthCubit>().resetError();
          }
        },
        builder: (context, state) {
          final loading = state is DashboardAuthLoading;
          final theme = Theme.of(context);

          return DashboardAuthLayout(
            action: const DashboardAuthThemeToggle(),
            form: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تسجيل مكتب جديد',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.ink(context),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  Text(
                    'أنشئ حساب المالك ولوحة تحكم مكتبك في خطوة واحدة.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DashboardColors.mutedInk(context),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXl),
                  AnimatedSize(
                    duration: AppTokens.motionBase,
                    alignment: Alignment.topCenter,
                    child: _error == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTokens.spaceLg,
                            ),
                            child: DashboardAuthErrorBanner(
                              message: _error!,
                              onDismiss: _clearError,
                            ),
                          ),
                  ),
                  AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _GroupLabel('بيانات المكتب'),
                        DashboardAuthField(
                          controller: _officeCtrl,
                          label: 'اسم المكتب',
                          hint: 'مثال: مكتب النيل للنقل',
                          icon: DashboardIcons.officeProfile,
                          enabled: !loading,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.organizationName],
                          onChanged: (_) => _clearError(),
                          validator: (v) {
                            final name = v?.trim() ?? '';
                            if (name.length < 3) return 'أدخل اسم المكتب';
                            if (name.length > 120) {
                              return 'اسم المكتب طويل جداً';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTokens.spaceXl),
                        const _GroupLabel('حساب المالك'),
                        DashboardAuthField(
                          controller: _emailCtrl,
                          label: 'البريد الإلكتروني',
                          hint: 'name@office.com',
                          icon: Icons.mail_outline_rounded,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) => _clearError(),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: AppTokens.spaceLg),
                        DashboardAuthField(
                          controller: _passCtrl,
                          label: 'كلمة المرور',
                          helper: 'ثمانية أحرف على الأقل.',
                          icon: DashboardIcons.locked,
                          obscureText: _obscure,
                          enabled: !loading,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) => _clearError(),
                          suffix: _RevealButton(
                            obscured: _obscure,
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) => (v?.length ?? 0) < 8
                              ? 'كلمة المرور 8 أحرف على الأقل'
                              : null,
                        ),
                        const SizedBox(height: AppTokens.spaceLg),
                        DashboardAuthField(
                          controller: _confirmCtrl,
                          label: 'تأكيد كلمة المرور',
                          icon: Icons.lock_reset_rounded,
                          obscureText: _obscureConfirm,
                          enabled: !loading,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => _clearError(),
                          onFieldSubmitted: (_) => loading ? null : _submit(),
                          suffix: _RevealButton(
                            obscured: _obscureConfirm,
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          validator: (v) => v == _passCtrl.text
                              ? null
                              : 'كلمتا المرور غير متطابقتين',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXl),
                  const _PublishNotice(),
                  const SizedBox(height: AppTokens.spaceXl),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'إنشاء المكتب',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXl),
                  const DashboardAuthDivider(),
                  const SizedBox(height: AppTokens.spaceLg),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : widget.onBackToLogin,
                      icon: const Icon(DashboardIcons.back, size: 19),
                      label: const Text(
                        'لديك حساب بالفعل؟ تسجيل الدخول',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Names the subject of the fields under it. The form creates two things at
/// once — an office and the account that owns it — and without the split it
/// reads as one list in which "اسم المكتب" and "البريد الإلكتروني" describe the
/// same party.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spaceMd),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: DashboardColors.faintInk(context),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// The show/hide control on a secret field. Shared by both password inputs so
/// the pair can never end up with different glyphs for the same state.
class _RevealButton extends StatelessWidget {
  const _RevealButton({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
      ),
      tooltip: obscured ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
    );
  }
}

/// Sets the expectation that publishing is a separate, platform-side step.
///
/// Drawn on the `info` tone rather than the plain nested surface the sign-in
/// screen's access note uses: that one is background an operator may never
/// need, this one is a condition on what they are about to create, and it has
/// to be read before the button under it is pressed.
class _PublishNotice extends StatelessWidget {
  const _PublishNotice();

  @override
  Widget build(BuildContext context) {
    final style = DashboardColors.status(context, AppStatusTone.info);

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(
          color: DashboardColors.statusLine(context, AppStatusTone.info),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(DashboardIcons.insight, size: 18, color: style.accent),
          const SizedBox(width: AppTokens.spaceSm),
          Expanded(
            child: Text(
              'ستتمكن من إدارة مكتبك فوراً. يظهر المكتب لعملاء التطبيق بعد '
              'مراجعته واعتماده من إدارة المنصة.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: style.ink, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
