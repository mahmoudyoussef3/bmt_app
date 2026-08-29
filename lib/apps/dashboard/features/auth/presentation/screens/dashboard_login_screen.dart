import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../cubit/dashboard_auth_cubit.dart';
import '../widgets/dashboard_auth_divider.dart';
import '../widgets/dashboard_auth_error_banner.dart';
import '../widgets/dashboard_auth_field.dart';
import '../widgets/dashboard_auth_layout.dart';
import '../widgets/dashboard_auth_theme_toggle.dart';

/// The console's front door.
///
/// Laid out as [DashboardAuthLayout]'s two-up split — the EWT brand sweep on
/// the leading side, this form on a plain console surface beside it — because
/// the dashboard is a desktop product and a 440px column floating in the middle
/// of a 1600px window reads as an unfinished page rather than a login.
class DashboardLoginScreen extends StatefulWidget {
  const DashboardLoginScreen({super.key, required this.onCreateOffice});

  final VoidCallback onCreateOffice;

  @override
  State<DashboardLoginScreen> createState() => _DashboardLoginScreenState();
}

class _DashboardLoginScreenState extends State<DashboardLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  /// The last sign-in failure, held here rather than read off the cubit state:
  /// [DashboardAuthCubit.resetError] returns the cubit to signed-out as soon as
  /// the message has been taken, so the form stays interactive while the banner
  /// is still on screen.
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<DashboardAuthCubit>().signIn(
      username: _nameCtrl.text.trim().toLowerCase(),
      password: _passCtrl.text,
    );
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
          return DashboardAuthLayout(
            action: const DashboardAuthThemeToggle(),
            form: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تسجيل الدخول',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.ink(context),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  Text(
                    'أدخل بيانات حسابك للمتابعة إلى لوحة تحكم مكتبك.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                        DashboardAuthField(
                          controller: _nameCtrl,
                          label: 'الاسم أو البريد الإلكتروني',
                          hint: 'name@office.com',
                          icon: DashboardIcons.captain,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          onChanged: (_) => _clearError(),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'أدخل الاسم أو البريد الإلكتروني'
                              : null,
                        ),
                        const SizedBox(height: AppTokens.spaceLg),
                        DashboardAuthField(
                          controller: _passCtrl,
                          label: 'كلمة المرور',
                          icon: DashboardIcons.locked,
                          obscureText: _obscure,
                          enabled: !loading,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onChanged: (_) => _clearError(),
                          onFieldSubmitted: (_) => loading ? null : _submit(),
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            tooltip: _obscure
                                ? 'إظهار كلمة المرور'
                                : 'إخفاء كلمة المرور',
                          ),
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? 'أدخل كلمة المرور' : null,
                        ),
                      ],
                    ),
                  ),
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
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'دخول',
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
                      onPressed: loading ? null : widget.onCreateOffice,
                      icon: const Icon(Icons.add_business_outlined, size: 19),
                      label: const Text(
                        'تسجيل مكتب جديد',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXl),
                  const _AccessNote(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Who this door is for. Kept as a quiet note rather than the old subtitle
/// under the title: it answers a question an operator only asks *after* a
/// failed attempt, so it belongs at the bottom of the form, not above it.
class _AccessNote extends StatelessWidget {
  const _AccessNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.divider(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            DashboardIcons.locked,
            size: 18,
            color: DashboardColors.mutedInk(context),
          ),
          const SizedBox(width: AppTokens.spaceSm),
          Expanded(
            child: Text(
              'الدخول مخصص لمالك المكتب وفريق خدمة العملاء. '
              'لأي مشكلة في الحساب، تواصل مع مالك المكتب.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
