import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Says, in one line, that the list above is the newest [rowCap] rows and not
/// the whole history.
///
/// Rendered only when the cap was actually reached, so an office that has never
/// come near it never sees the sentence. Deliberately quiet — it is a scope
/// note, not a warning: nothing has gone wrong, the console simply cannot show
/// an unbounded list and is saying which end of it you are reading.
///
/// One widget rather than one per module: this replaced a private copy in
/// المركز المالي, and every list that gains a cap gains the same sentence in
/// the same place.
class DashboardCapNotice extends StatelessWidget {
  const DashboardCapNotice({
    super.key,
    required this.rowCap,
    required this.noun,
    this.hint = 'ضيّق الفلاتر للوصول لسجلات أقدم.',
  });

  /// The ceiling that was hit.
  final int rowCap;

  /// What is being counted, already in the plural the sentence needs —
  /// `'حجز'`, `'رحلة'`, `'شكوى'`.
  final String noun;

  /// What the operator can do about it. Pass an empty string where narrowing
  /// the filters would not in fact reach older rows.
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.bodySmall;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      // Wraps rather than clipping: at 1.6× text scale in a narrow window the
      // sentence is wider than any toolbar it sits in, and the numbers are the
      // whole content — an ellipsis would delete them.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: scheme.onSurface),
          const SizedBox(width: AppSpacing.xSmall),
          Flexible(
            child: Text(
              hint.isEmpty
                  ? 'يعرض أحدث $rowCap $noun'
                  : 'يعرض أحدث $rowCap $noun. $hint',
              style: text,
            ),
          ),
        ],
      ),
    );
  }
}
