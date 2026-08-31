import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/core/theme/spacing.dart';

/// The console's one input control.
///
/// Every operational form (driver, vehicle, trip, route) draws its fields with
/// these three widgets so a field looks and behaves the same wherever an
/// operator meets it. Three things are deliberate:
///
/// * **The label is a name, never an instruction.** "الرقم القومي", not
///   "الرقم القومي (14 رقماً مصرياً)" — a floating label truncates, and an
///   instruction that disappears the moment the field has focus is not an
///   instruction. Constraints belong in [helper], examples in [hint].
/// * **Required is marked on the label, before the operator commits.** A red
///   `*` next to the label name rather than an error discovered at save time.
///   The label itself stays a plain [Text] so it is still addressable by its
///   own words.
/// * **The keyboard advances.** [nextFocus] chains a field to the one after
///   it, so a whole form is fillable without reaching for the mouse; the last
///   field in a chain takes [onSubmitted] instead.
class DashboardFormField extends StatelessWidget {
  const DashboardFormField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.hint,
    this.helper,
    this.isRequired = true,
    this.focusNode,
    this.nextFocus,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;

  /// What the field *is*. Short enough to survive floating over the input.
  final String label;

  final IconData? icon;

  /// An example of a good answer, shown only while the field is empty.
  final String? hint;

  /// The rule or consequence, shown permanently under the field.
  final String? helper;

  final bool isRequired;
  final FocusNode? focusNode;

  /// The field the keyboard moves to on Enter / "next".
  final FocusNode? nextFocus;

  /// Runs on Enter when there is no [nextFocus] — the submit shortcut.
  final VoidCallback? onSubmitted;

  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  /// Hard ceiling on the answer, with the counter Material draws for it. Use it
  /// where the column itself is bounded — a description the marketplace card
  /// has to fit — so the limit is visible while typing rather than discovered
  /// by a rejected save.
  final int? maxLength;

  final bool readOnly;

  /// False greys the control out entirely — the field is not the operator's to
  /// fill right now (a role that may only read, a form mid-save). Distinct from
  /// [readOnly], which keeps a value at full contrast because it is still worth
  /// reading, just not typing into.
  final bool enabled;

  final bool autofocus;
  final TextCapitalization textCapitalization;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final multiline = maxLines > 1;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType:
          keyboardType ?? (multiline ? TextInputType.multiline : null),
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      textInputAction: multiline
          ? TextInputAction.newline
          : (nextFocus != null ? TextInputAction.next : TextInputAction.done),
      onFieldSubmitted: multiline
          ? null
          : (_) {
              if (nextFocus != null) {
                nextFocus!.requestFocus();
              } else {
                onSubmitted?.call();
              }
            },
      decoration: InputDecoration(
        label: DashboardFieldLabel(text: label, isRequired: isRequired),
        hintText: hint,
        helperText: helper,
        helperMaxLines: 3,
        errorMaxLines: 3,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffix,
        // A multi-line field's label belongs at the top of the box; centred in
        // the middle of four empty lines it reads as placeholder text.
        alignLabelWithHint: multiline,
        filled: readOnly,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// The dropdown twin of [DashboardFormField] — same label treatment, same
/// helper/required contract, so a picker never reads as a lesser field than
/// the text inputs beside it.
class DashboardDropdownFormField<T> extends StatelessWidget {
  const DashboardDropdownFormField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.icon,
    this.helper,
    this.isRequired = true,
    this.validator,
    this.focusNode,
  });

  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData? icon;
  final String? helper;
  final bool isRequired;
  final String? Function(T?)? validator;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      focusNode: focusNode,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        label: DashboardFieldLabel(text: label, isRequired: isRequired),
        helperText: helper,
        helperMaxLines: 3,
        errorMaxLines: 3,
        prefixIcon: icon == null ? null : Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// A date field that opens a picker instead of asking anyone to type
/// `YYYY-MM-DD` by hand, and shows the chosen day in words next to the stored
/// ISO value so a mis-picked year is obvious at a glance.
///
/// The control is read-only on purpose: the value it writes is the exact
/// string the datasource stores, and a free-text date is the single most
/// common way that contract gets broken.
class DashboardDateFormField extends StatelessWidget {
  const DashboardDateFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.onPicked,
    this.helper,
    this.isRequired = true,
    this.validator,
    this.firstDate,
    this.lastDate,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;

  /// Called with the ISO `yyyy-MM-dd` string once a day is chosen.
  final ValueChanged<String> onPicked;

  final String? helper;
  final bool isRequired;
  final String? Function(String?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final first =
        firstDate ?? DateTime.now().subtract(const Duration(days: 3650));
    final last = lastDate ?? DateTime.now().add(const Duration(days: 3650));

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: true,
      validator: validator,
      decoration: InputDecoration(
        label: DashboardFieldLabel(text: label, isRequired: isRequired),
        helperText: helper ?? _relativeHelper(controller.text),
        helperMaxLines: 2,
        errorMaxLines: 3,
        prefixIcon: const Icon(Icons.calendar_today_rounded),
        suffixIcon: const Icon(Icons.expand_more_rounded),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        final parsed = DateTime.tryParse(controller.text);
        final initial =
            parsed != null && !parsed.isBefore(first) && !parsed.isAfter(last)
            ? parsed
            : (first.isAfter(DateTime.now()) ? first : DateTime.now());
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: first,
          lastDate: last,
        );
        if (picked == null) return;
        onPicked(picked.toIso8601String().substring(0, 10));
      },
    );
  }

  /// "بعد ٨ أشهر" / "منتهية منذ ١٢ يوماً" — the fact an operator actually needs
  /// from a licence or inspection date, spelled out under the raw value.
  static String? _relativeHelper(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return null;
    final now = DateTime.now();
    final days = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0) return 'اليوم';
    if (days > 0) {
      if (days < 30) return 'بعد $days يوماً';
      final months = (days / 30).round();
      return months < 12
          ? 'بعد $months شهراً'
          : 'بعد ${(days / 365).round()} سنة';
    }
    final past = -days;
    if (past < 30) return 'منذ $past يوماً';
    final months = (past / 30).round();
    return months < 12
        ? 'منذ $months شهراً'
        : 'منذ ${(past / 365).round()} سنة';
  }
}

/// The label half of a console field: the field's name, plus a red `*` when an
/// answer is mandatory.
///
/// The name stays its own bare [Text] so tests and screen readers still see
/// exactly the words the operator sees, with no marker glued onto them.
class DashboardFieldLabel extends StatelessWidget {
  const DashboardFieldLabel({
    super.key,
    required this.text,
    this.isRequired = true,
  });

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    if (!isRequired) return Text(text);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        Text(
          ' *',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

/// Lays fields out in columns that collapse to one on a narrow dialog.
///
/// Replaces the three near-identical `_responsiveGrid` helpers the fleet forms
/// each grew privately. [columns] is a ceiling, not a promise — the grid drops
/// to one column below [breakpoint] whatever it is asked for.
class DashboardFieldGrid extends StatelessWidget {
  const DashboardFieldGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.breakpoint = 720,
  });

  final List<Widget> children;
  final int columns;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= breakpoint ? columns : 1;
        if (count == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.medium),
                children[i],
              ],
            ],
          );
        }
        final itemWidth =
            (constraints.maxWidth - AppSpacing.medium * (count - 1)) / count;
        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
