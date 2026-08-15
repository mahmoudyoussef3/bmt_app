import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/staff_account.dart';

/// The fields that make a colleague a dashboard login.
///
/// Four inputs and nothing else, because there is nothing else to decide: the office is
/// the one the owner is signed into, the account is created active, and the login
/// address is derived from the name server-side. Anything this form *could* ask that
/// the server decides anyway would be a control that lies about who is in charge.
///
/// The role picker carries its own explanation of what each role can reach. An owner
/// choosing between «المالك» and «خدمة العملاء» with no idea what the second one sees
/// will pick the first, and an office where everyone is an owner has no permissions at
/// all.
class StaffAccountForm extends StatefulWidget {
  const StaffAccountForm({
    super.key,
    required this.isSubmitting,
    required this.fieldErrors,
    required this.onSubmit,
  });

  final bool isSubmitting;

  /// Server- or use-case-side validation errors, keyed as
  /// [StaffAccountRequest.validate] keys them.
  final Map<String, String> fieldErrors;

  final ValueChanged<StaffAccountRequest> onSubmit;

  @override
  State<StaffAccountForm> createState() => _StaffAccountFormState();
}

class _StaffAccountFormState extends State<StaffAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  DashboardRole _role = DashboardRole.supportAgent;
  bool _generatePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  StaffAccountRequest _buildRequest() => StaffAccountRequest(
    username: _usernameCtrl.text,
    fullName: _fullNameCtrl.text,
    role: _role,
    password: _generatePassword ? '' : _passwordCtrl.text,
  );

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_buildRequest());
  }

  /// Prefers the local rule, falls back to whatever the server rejected the field for.
  /// The two agree by construction; when they disagree the server is the one that
  /// matters.
  String? _errorFor(String field, String? Function() local) {
    return local() ?? widget.fieldErrors[field];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = !widget.isSubmitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _fullNameCtrl,
            enabled: enabled,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'اسم الموظف',
              helperText: 'يظهر داخل لوحة التحكم بجانب أفعاله.',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _errorFor('fullName', () {
              if ((value ?? '').trim().length > 120) return 'الاسم طويل جداً';
              return null;
            }),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _usernameCtrl,
            enabled: enabled,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'اسم الدخول *',
              helperText: 'حروف إنجليزية صغيرة وأرقام و . _ - فقط. لا يمكن تغييره لاحقاً.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
            validator: (value) => _errorFor('username', () {
              return StaffAccountRequest(
                username: (value ?? '').trim().toLowerCase(),
              ).validate()['username'];
            }),
          ),
          const SizedBox(height: AppSpacing.medium),
          DropdownButtonFormField<DashboardRole>(
            initialValue: _role,
            decoration: const InputDecoration(
              labelText: 'الدور *',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final role in DashboardRole.values)
                DropdownMenuItem(value: role, child: Text(role.label)),
            ],
            onChanged: enabled
                ? (role) => setState(() => _role = role ?? _role)
                : null,
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            _roleDescription(_role),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          SwitchListTile(
            value: _generatePassword,
            onChanged: enabled
                ? (value) => setState(() => _generatePassword = value)
                : null,
            contentPadding: EdgeInsets.zero,
            title: const Text('توليد كلمة مرور تلقائياً'),
            subtitle: const Text(
              'تُعرض مرة واحدة بعد الإنشاء ولا يمكن استرجاعها.',
            ),
          ),
          if (!_generatePassword) ...[
            const SizedBox(height: AppSpacing.small),
            TextFormField(
              controller: _passwordCtrl,
              enabled: enabled,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور *',
                helperText: '10 أحرف على الأقل.',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _errorFor('password', () {
                if ((value ?? '').length < 10) {
                  return 'كلمة المرور 10 أحرف على الأقل';
                }
                return null;
              }),
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: enabled ? _submit : null,
              icon: widget.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                widget.isSubmitting ? 'جارٍ الإنشاء…' : 'إنشاء الحساب',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What each role can actually reach, in the operator's words rather than the
/// permission enum's. Kept in sync with `DashboardPermissions.permissionsFor`.
String _roleDescription(DashboardRole role) => switch (role) {
  DashboardRole.admin =>
    'وصول كامل: الرحلات والأسطول والمسارات والحسابات والتقارير وإدارة '
        'المستخدمين نفسها.',
  DashboardRole.supportAgent =>
    'الحجوزات وتذاكر الدعم ومراجعة المدفوعات ومحافظ العملاء والمتابعة '
        'المباشرة والتقارير. لا يصل إلى الأسطول أو المسارات أو إدارة المستخدمين.',
};
