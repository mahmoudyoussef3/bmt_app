import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../cubit/captain_auth_cubit.dart';
import '../widgets/captain_auth_error_banner.dart';
import '../widgets/captain_auth_field.dart';
import '../widgets/captain_auth_header.dart';
import '../widgets/captain_auth_scaffold.dart';
import 'captain_request_access_screen.dart';

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

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CaptainAuthCubit>().signIn(phone: _phoneCtrl.text.trim());
  }

  void _openRequestAccess() {
    final swap = widget.onRequestAccess;
    if (swap != null) {
      swap();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CaptainRequestAccessScreen()),
    );
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
                    const CaptainAuthHeader(
                      title: 'تسجيل دخول الكابتن',
                      subtitle:
                          'أدخل رقم هاتفك المسجّل لعرض رحلاتك والبدء بالقيادة.',
                    ),
                    const SizedBox(height: 40),
                    CaptainAuthErrorBanner(
                      message: error,
                      onDismiss: cubit.resetError,
                    ),
                    CaptainAuthField(
                      controller: _phoneCtrl,
                      label: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      onSubmitted: (_) => _submit(),
                      validator: (value) {
                        final digits = (value ?? '').replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        return digits.length < 10 ? 'أدخل رقم هاتف صحيح' : null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CaptainButton(
                      label: loading ? 'جارٍ تسجيل الدخول...' : 'تسجيل الدخول',
                      isLoading: loading,
                      onPressed: loading ? null : _submit,
                    ),
                    const SizedBox(height: 20),
                    _RequestAccessLink(
                      onTap: loading ? null : _openRequestAccess,
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

class _RequestAccessLink extends StatelessWidget {
  const _RequestAccessLink({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'كابتن جديد؟',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'اطلب الانضمام',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
