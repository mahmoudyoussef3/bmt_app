import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
///
/// The form draws **no submit button of its own**. The action lives in the hosting
/// dialog's pinned action bar and drives this widget through
/// [StaffAccountFormState.submit] on a [GlobalKey] — see [StaffAccountForm.new]. A
/// primary action inside a scrolling body is a primary action the operator cannot find
/// on a short window, which is exactly how this dialog came to look like it did
/// nothing.
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
  StaffAccountFormState createState() => StaffAccountFormState();
}

class StaffAccountFormState extends State<StaffAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  /// The exact text each field held when the server last refused it.
  ///
  /// Without this the refusal is permanent: [widget.fieldErrors] only changes on the
  /// *next* submission, and the validator that reads it keeps failing the field the
  /// operator has already corrected — so `validate()` returns false, [submit] returns
  /// early, no new state is ever emitted, and the button silently stops working. A
  /// server error is consumed once, against the value that earned it.
  final _rejectedValues = <String, String>{};

  DashboardRole _role = DashboardRole.supportAgent;
  bool _generatePassword = true;
  bool _showPassword = false;

  @override
  void didUpdateWidget(StaffAccountForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.fieldErrors, widget.fieldErrors)) return;
    _rejectedValues
      ..clear()
      ..addEntries(
        widget.fieldErrors.keys.map(
          (field) => MapEntry(field, _controllerFor(field)?.text ?? ''),
        ),
      );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  StaffAccountRequest _buildRequest() => StaffAccountRequest(
    username: _usernameCtrl.text,
    fullName: _fullNameCtrl.text,
    role: _role,
    password: _generatePassword ? '' : _passwordCtrl.text,
  );

  /// Validates and hands the request up. Called by the dialog's action button.
  void submit() {
    if (widget.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_buildRequest());
  }

  TextEditingController? _controllerFor(String field) => switch (field) {
    'username' => _usernameCtrl,
    'fullName' => _fullNameCtrl,
    'password' => _passwordCtrl,
    _ => null,
  };

  /// Prefers the local rule, falls back to whatever the server rejected the field for.
  /// The two agree by construction; when they disagree the server is the one that
  /// matters — but only for as long as the field still holds the value it refused.
  String? _errorFor(String field, String? Function() local) {
    final localError = local();
    if (localError != null) return localError;

    final serverError = widget.fieldErrors[field];
    if (serverError == null) return null;

    final rejected = _rejectedValues[field];
    if (rejected != null && (_controllerFor(field)?.text ?? '') != rejected) {
      return null;
    }
    return serverError;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = !widget.isSubmitting;

    return Form(
      key: _formKey,
      // Errors clear as the operator types instead of only on the next submission, so
      // a corrected field stops looking refused the moment it stops being wrong.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _fullNameCtrl,
            enabled: enabled,
            autofocus: true,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            onFieldSubmitted: (_) => _usernameFocus.requestFocus(),
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
            focusNode: _usernameFocus,
            enabled: enabled,
            textInputAction: TextInputAction.next,
            // Latin text in an Arabic console: left-to-right, or `ops.sara` renders
            // with its separators shuffled and the owner cannot proof-read the name
            // they are about to hand out.
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            // The rule is enforced as you type rather than reported after the fact:
            // the server lowercases the name anyway, so refusing «Sara» would be the
            // form complaining about something it was going to fix itself.
            inputFormatters: [
              LengthLimitingTextInputFormatter(32),
              _LowercaseUsernameFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'اسم الدخول *',
              helperText:
                  'حروف إنجليزية صغيرة وأرقام و . _ - فقط. لا يمكن تغييره لاحقاً.',
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
              focusNode: _passwordFocus,
              enabled: enabled,
              obscureText: !_showPassword,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => submit(),
              decoration: InputDecoration(
                labelText: 'كلمة المرور *',
                helperText: '10 أحرف على الأقل.',
                border: const OutlineInputBorder(),
                // The owner has to read this password aloud to a colleague, so they
                // are allowed to see what they typed before it becomes the one thing
                // standing between that colleague and the console.
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'إخفاء' : 'إظهار',
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: (value) => _errorFor('password', () {
                if ((value ?? '').length < 10) {
                  return 'كلمة المرور 10 أحرف على الأقل';
                }
                return null;
              }),
            ),
          ],
        ],
      ),
    );
  }
}

/// Keeps the login name in the only shape the server accepts, as it is typed.
///
/// Uppercase is folded (the server lowercases it anyway) and characters outside
/// `[a-z0-9._-]` are dropped, so an Arabic keyboard left on by accident produces an
/// empty field the operator can see rather than a name the server refuses after a round
/// trip.
class _LowercaseUsernameFormatter extends TextInputFormatter {
  static final _allowed = RegExp(r'[a-z0-9._-]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    var removedBeforeCaret = 0;
    final caret = newValue.selection.baseOffset;

    for (var i = 0; i < newValue.text.length; i++) {
      final char = newValue.text[i].toLowerCase();
      if (_allowed.hasMatch(char)) {
        buffer.write(char);
      } else if (caret >= 0 && i < caret) {
        removedBeforeCaret++;
      }
    }

    final text = buffer.toString();
    final offset = caret < 0
        ? text.length
        : (caret - removedBeforeCaret).clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
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
