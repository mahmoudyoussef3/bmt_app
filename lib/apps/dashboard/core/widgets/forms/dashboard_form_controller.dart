import 'package:flutter/material.dart';

/// One unmet requirement in a form, in the operator's words.
///
/// Carries enough to *act* on: which field, what is wrong, and where it is on
/// screen — so the summary at the top of a form can put the caret in the field
/// rather than only naming it.
class DashboardFormIssue {
  const DashboardFormIssue({
    required this.fieldId,
    required this.label,
    required this.message,
  });

  /// Matches the id the field was registered under.
  final String fieldId;

  /// The field's own name, as it reads on its label.
  final String label;

  /// Why it is not acceptable yet.
  final String message;
}

/// A field the form knows how to validate, count, and scroll to.
class DashboardFormFieldSpec {
  const DashboardFormFieldSpec({
    required this.id,
    required this.label,
    required this.anchorKey,
    required this.validate,
    this.focusNode,
    this.isRequired = true,
    this.section,
  });

  final String id;
  final String label;

  /// Placed on the field's own widget, so the summary can scroll it into view.
  final GlobalKey anchorKey;

  /// The same rule the field's own `validator` runs — read from here so a
  /// single definition drives the inline error, the summary, and the counter.
  final String? Function() validate;

  final FocusNode? focusNode;

  /// Optional-but-tracked fields still validate (a badly formed phone is an
  /// error even when a phone was not demanded); they just never count against
  /// the completion total.
  final bool isRequired;

  /// The section heading this field sits under, used to say *where* an
  /// unfinished field is without making the operator hunt for it.
  final String? section;
}

/// The completion and error model behind a console form.
///
/// A long operational form fails in one of two ways: the operator submits and
/// is told "fix the red fields" with no idea which or where, or they cannot
/// tell how much is left before they start. This holds one declaration per
/// field — its rule, its name, its position — and answers both from it:
/// [issues] for what is still wrong, [requiredFilled]/[requiredTotal] for how
/// far along they are, and [jumpTo] to put them in the field itself.
class DashboardFormController {
  DashboardFormController(this.fields);

  final List<DashboardFormFieldSpec> fields;

  /// Every unmet rule, in the order the fields appear on screen — so "the
  /// first issue" is always the topmost one, the one an operator scrolling
  /// down would meet next.
  List<DashboardFormIssue> get issues => [
    for (final field in fields)
      if (field.validate() case final message?)
        DashboardFormIssue(
          fieldId: field.id,
          label: field.label,
          message: message,
        ),
  ];

  bool get isValid => issues.isEmpty;

  int get requiredTotal => fields.where((f) => f.isRequired).length;

  /// Required fields currently passing their own rule — i.e. genuinely done,
  /// not merely non-empty.
  int get requiredFilled =>
      fields.where((f) => f.isRequired && f.validate() == null).length;

  double get progress =>
      requiredTotal == 0 ? 1 : requiredFilled / requiredTotal;

  DashboardFormFieldSpec? fieldById(String id) =>
      fields.where((field) => field.id == id).firstOrNull;

  /// Scrolls a field into view and focuses it.
  ///
  /// Both halves matter: scrolling alone leaves the operator to click, and
  /// focusing alone can put the caret in a field below the fold. Silently does
  /// nothing when the field is not currently mounted (a collapsed section, a
  /// branch of the form that does not apply) rather than throwing.
  Future<void> jumpTo(String fieldId) async {
    final field = fieldById(fieldId);
    final context = field?.anchorKey.currentContext;
    if (field == null || context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
    );
    field.focusNode?.requestFocus();
  }

  /// Jumps to the first unmet rule. Returns false when there is nothing to fix.
  Future<bool> jumpToFirstIssue() async {
    final first = issues.firstOrNull;
    if (first == null) return false;
    await jumpTo(first.fieldId);
    return true;
  }
}
