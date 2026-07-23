import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/dashboard_auth_cubit.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Self-service office registration: email, password, office name.
///
/// Deliberately three fields and no more. The login screen asks for a Name, but the
/// operator filling this form has not chosen one — the server derives it from the email
/// — and `resolve_office_user_login` accepts the email address itself, so they sign in
/// afterwards with exactly what they typed here.
///
/// The office this creates is workable immediately and invisible to passengers until the
/// platform publishes it, which is what the notice at the bottom says out loud: an
/// operator who is not told that will read an empty marketplace as a broken product.
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

  @override
  void dispose() {
    _officeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
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
    // Matches the server's own check in register_office, so a value that passes here
    // is not rejected a round-trip later.
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$').hasMatch(email);
    return valid ? null : 'البريد الإلكتروني غير صالح';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: BlocConsumer<DashboardAuthCubit, DashboardAuthState>(
          listener: (context, state) {
            if (state is DashboardAuthError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 6),
              ));
              context.read<DashboardAuthCubit>().resetError();
            }
          },
          builder: (context, state) {
            final loading = state is DashboardAuthLoading;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(AppTokens.radius),
                              ),
                              child: Icon(
                                Icons.add_business_rounded,
                                size: 28,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'تسجيل مكتب جديد',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'أنشئ حساب المالك ولوحة تحكم مكتبك',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 36),
                        TextFormField(
                          controller: _officeCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'اسم المكتب',
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
                          validator: (v) {
                            final name = v?.trim() ?? '';
                            if (name.length < 3) return 'أدخل اسم المكتب';
                            if (name.length > 120) return 'اسم المكتب طويل جداً';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v?.length ?? 0) < 8
                              ? 'كلمة المرور 8 أحرف على الأقل'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                            prefixIcon: Icon(Icons.lock_reset_rounded),
                          ),
                          validator: (v) => v == _passCtrl.text
                              ? null
                              : 'كلمتا المرور غير متطابقتين',
                        ),
                        const SizedBox(height: 24),
                        _DraftNotice(scheme: scheme),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: loading ? null : _submit,
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'إنشاء المكتب',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: loading ? null : widget.onBackToLogin,
                          child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Sets the expectation that publishing is a separate, platform-side step.
class _DraftNotice extends StatelessWidget {
  const _DraftNotice({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ستتمكن من إدارة مكتبك فوراً. يظهر المكتب لعملاء التطبيق بعد '
              'مراجعته واعتماده من إدارة المنصة.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
