import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../../domain/entities/office_license.dart';

/// The small vocabulary every licensing screen shares, so the console reads as
/// one module rather than seven screens that happen to sit together.

/// A licence status, in the platform's colour language.
class LicenseStatusChip extends StatelessWidget {
  const LicenseStatusChip({super.key, required this.status, this.label});

  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final color = switch (status) {
      'active' => scheme.secondary,
      'trialing' => scheme.tertiary,
      'past_due' || 'grace' => scheme.tertiary,
      'suspended' || 'cancelled' || 'expired' => scheme.error,
      _ => scheme.outline,
    };
    return StatusChip(
      label: label ?? status,
      color: color.withAlpha(24),
      textColor: color,
    );
  }
}

/// enforced / declared, on a catalog row.
///
/// The badge exists because half the catalog has no code behind it yet, and
/// shipping flags that silently do nothing is how a licensing system loses
/// credibility internally.
class EnforcementBadge extends StatelessWidget {
  const EnforcementBadge({super.key, required this.isEnforced});

  final bool isEnforced;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isEnforced ? scheme.secondary : scheme.tertiary;
    return Tooltip(
      message: isEnforced
          ? 'مفعّلة فعليًا: يوجد كود يطبّقها.'
          : 'معلنة فقط: مُدرجة في الكتالوج ولا يوجد كود يطبّقها بعد.',
      child: StatusChip(
        label: isEnforced ? 'مطبَّقة' : 'غير مفعّلة بعد',
        color: color.withAlpha(24),
        textColor: color,
      ),
    );
  }
}

/// used / limit, with an honest over-limit state.
///
/// Over-limit is drawn in the danger colour and labelled with the overage,
/// rather than clamped to 100% — an office that downgraded from 50 drivers to
/// 10 is genuinely over by 40, keeps all 40, and the console should say so.
class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.label,
    required this.used,
    required this.limit,
    this.unit = '',
    this.dense = false,
  });

  final String label;
  final int used;

  /// Null means unlimited.
  final int? limit;

  final String unit;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final unlimited = limit == null;
    final over = !unlimited && used > limit!;
    final ratio = unlimited || limit == 0
        ? 0.0
        : (used / limit!).clamp(0.0, 1.0).toDouble();
    final color = over
        ? scheme.error
        : (ratio >= 0.85 ? scheme.tertiary : scheme.primary);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4 : AppSpacing.xSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodySmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                unlimited
                    ? '$used — بلا حدود'
                    : '$used / $limit${unit.isEmpty ? '' : ' $unit'}',
                style: text.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: over ? scheme.error : null,
                ),
              ),
              if (over) ...[
                const SizedBox(width: AppSpacing.xSmall),
                Text(
                  'تجاوز ${used - limit!}',
                  style: text.labelSmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: unlimited ? 0 : (over ? 1 : ratio),
              minHeight: 6,
              backgroundColor: DashboardColors.well(context),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// The typed control for one feature value: a switch, a number field with a
/// "بلا حدود" toggle, a dropdown, or a text field — chosen by `value_type`.
///
/// This is the whole reason the catalog carries type metadata: values are jsonb
/// so a new feature costs one INSERT and zero deploys, and the type safety that
/// bought was moved into the catalog rather than given up.
class FeatureValueField extends StatelessWidget {
  const FeatureValueField({
    super.key,
    required this.feature,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final CatalogFeature feature;

  /// Null means "no value set at this level" — for a plan that is "fall through
  /// to the catalog default", which is a different statement from `false`.
  final Object? value;

  final ValueChanged<Object?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    switch (feature.valueType) {
      case 'boolean':
        return Switch(
          value: FeatureValue.truthy(value ?? feature.defaultValue),
          onChanged: enabled ? onChanged : null,
        );

      case 'limit':
        final unlimited = FeatureValue.isUnlimited(value);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!unlimited)
              SizedBox(
                width: 96,
                child: TextFormField(
                  key: ValueKey('${feature.key}-limit'),
                  initialValue: value is num ? '$value' : '',
                  enabled: enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (raw) {
                    final parsed = int.tryParse(raw.trim());
                    if (parsed != null && parsed >= 0) onChanged(parsed);
                  },
                ),
              ),
            const SizedBox(width: AppSpacing.small),
            FilterChip(
              label: const Text('بلا حدود'),
              selected: unlimited,
              onSelected: enabled
                  ? (on) => onChanged(on ? FeatureValue.unlimited : 0)
                  : null,
            ),
          ],
        );

      case 'enum':
        return DropdownButton<String>(
          value: value is String && feature.allowedValues.contains(value)
              ? value as String
              : (feature.defaultValue is String
                    ? feature.defaultValue as String
                    : feature.allowedValues.firstOrNull),
          items: [
            for (final v in feature.allowedValues)
              DropdownMenuItem(value: v, child: Text(v)),
          ],
          onChanged: enabled ? (v) => onChanged(v) : null,
        );

      default:
        return SizedBox(
          width: 180,
          child: TextFormField(
            key: ValueKey('${feature.key}-config'),
            initialValue: value == null ? '' : '$value',
            enabled: enabled,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (raw) {
              final trimmed = raw.trim();
              final asInt = int.tryParse(trimmed);
              onChanged(asInt ?? trimmed);
            },
          ),
        );
    }
  }
}

/// Names the rung of the ladder that produced a value.
///
/// This is what turns "why does this office have this?" from a twenty-minute
/// support conversation into one click.
class FeatureSourceChip extends StatelessWidget {
  const FeatureSourceChip({super.key, required this.source, this.blockedBy});

  final String source;
  final String? blockedBy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (source) {
      'kill_switch' => ('مفتاح إيقاف المنصة', scheme.error),
      'license_hold' => ('حالة الترخيص', scheme.error),
      'override' => ('استثناء', scheme.tertiary),
      'plan' => ('الباقة', scheme.primary),
      _ => ('الافتراضي', scheme.outline),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusChip(label: label, color: color.withAlpha(20), textColor: color),
        if (blockedBy != null) ...[
          const SizedBox(width: AppSpacing.xSmall),
          Tooltip(
            message: 'مُعطَّلة لأن «$blockedBy» غير مفعّلة',
            child: Icon(DashboardIcons.locked, size: 16, color: scheme.error),
          ),
        ],
      ],
    );
  }
}

/// ▲ upgrade / ▼ restriction, read from the plan value rather than assumed.
class OverrideDirectionIcon extends StatelessWidget {
  const OverrideDirectionIcon({super.key, required this.isUpgrade});

  final bool? isUpgrade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (isUpgrade == null) {
      return Icon(Icons.remove, size: 16, color: scheme.outline);
    }
    return Icon(
      isUpgrade! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      size: 16,
      color: isUpgrade! ? scheme.secondary : scheme.error,
    );
  }
}

/// Asks for the reason the *server* requires.
///
/// Only the actions whose RPC enforces a reason still open this — suspending a
/// licence, extending a trial, creating or clearing an override. Saving a plan
/// no longer does: `platform_save_plan` requires nothing, writes the revision
/// either way, and demanding eight characters before every single save was the
/// main reason this console felt hostile to touch.
///
/// [suggestions] are one-tap fills. The reason still has to be true, but the
/// true one is usually one of three, and retyping it every time buys nothing.
Future<String?> promptForReason(
  BuildContext context, {
  required String title,
  String? description,
  String confirmLabel = 'تأكيد',
  int minLength = 8,
  List<String> suggestions = const [],
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ReasonDialog(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      minLength: minLength,
      suggestions: suggestions,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.minLength,
    required this.suggestions,
  });

  final String title;
  final String? description;
  final String confirmLabel;
  final int minLength;
  final List<String> suggestions;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.description != null) ...[
                  Text(
                    widget.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 2,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'السبب',
                    hintText: 'يظهر في سجل التغييرات',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v ?? '').trim().length < widget.minLength
                      ? 'اكتب سببًا واضحًا (${widget.minLength} أحرف على الأقل)'
                      : null,
                ),
                if (widget.suggestions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.xSmall,
                    runSpacing: AppSpacing.xSmall,
                    children: [
                      for (final suggestion in widget.suggestions)
                        ActionChip(
                          label: Text(suggestion),
                          onPressed: () => setState(() {
                            _controller.text = suggestion;
                          }),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// A compact list of offices for the health screen's sections.
class HealthList extends StatelessWidget {
  const HealthList({
    super.key,
    required this.icon,
    required this.title,
    required this.rows,
    required this.describe,
    this.emptyLabel = 'لا يوجد',
    this.onTapOffice,
    this.maxRows = 5,
  });

  final IconData icon;
  final String title;
  final List<Map<String, dynamic>> rows;
  final String Function(Map<String, dynamic>) describe;
  final String emptyLabel;
  final ValueChanged<String>? onTapOffice;

  /// How many offices are listed before the card summarises the rest. The card
  /// lives in a header strip, so it stays short by design and the full list is
  /// reached from the screen the signal belongs to.
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  title,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              StatusChip(
                label: '${rows.length}',
                color: (rows.isEmpty ? scheme.outline : scheme.tertiary)
                    .withAlpha(24),
                textColor: rows.isEmpty ? scheme.outline : scheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          if (rows.isEmpty)
            Text(
              emptyLabel,
              style: text.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            )
          else
            for (final row in rows.take(maxRows))
              InkWell(
                onTap: onTapOffice == null || row['office_id'] == null
                    ? null
                    : () => onTapOffice!(row['office_id'] as String),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    describe(row),
                    style: text.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          if (rows.length > maxRows)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'و${rows.length - maxRows} أخرى',
                style: text.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shows an action's outcome without ever replacing the screen the operator is
/// working in.
void showLicensingFeedback(BuildContext context, PlatformLicensingFeedback f) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(f.message),
        backgroundColor: f.isError ? scheme.error : null,
        duration: Duration(seconds: f.isError ? 6 : 5),
      ),
    );
}

class PlatformLicensingFeedback {
  const PlatformLicensingFeedback(this.message, {this.isError = false});
  final String message;
  final bool isError;
}

/// Formats a money figure the one way this console formats money.
String licensingMoney(num? value, [String currency = 'EGP']) {
  if (value == null) return '—';
  final rounded = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  return '$rounded ${currency == 'EGP' ? 'ج.م' : currency}';
}

/// `2026-08-06`, the one date format this console uses.
String licensingDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$m-$d';
}

/// A read-only summary line used across the office detail panel.
class LicensingField extends StatelessWidget {
  const LicensingField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// The override list, with its direction, reason and expiry.
class OverrideTile extends StatelessWidget {
  const OverrideTile({super.key, required this.entry, this.onClear});

  final FeatureOverride entry;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OverrideDirectionIcon(isUpgrade: entry.isUpgrade),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.nameAr,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: entry.expired
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      FeatureValue.label(entry.value),
                      style: text.bodySmall?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
                Text(
                  entry.reason,
                  style: text.bodySmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
                if (entry.expiresAt != null)
                  Text(
                    entry.expired
                        ? 'انتهى في ${licensingDate(entry.expiresAt)} — لم يعد ساريًا'
                        : 'ينتهي في ${licensingDate(entry.expiresAt)}',
                    style: text.labelSmall?.copyWith(
                      color: entry.expired
                          ? scheme.error
                          : DashboardColors.mutedInk(context),
                    ),
                  ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'إزالة الاستثناء',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}
