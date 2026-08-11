import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../../domain/entities/office_license.dart';
import 'licensing_widgets.dart';

/// The vocabulary the decision trail is read in.
///
/// The audit table stores machine references, because that is what a trigger
/// can capture without trusting the caller: a feature key, a plan uuid, and the
/// literal `true` primary key of the single settings row. Printing those raw is
/// what made this screen unreadable — a column of `max_captains`, `true` and
/// bare uuids that answered nothing. This resolves every reference against the
/// catalog the operator already knows, and the raw value is kept for the detail
/// panel, where an auditor can still see exactly what the row said.
class AuditLabels {
  AuditLabels({
    required List<CatalogFeature> features,
    required List<LicensingPlan> plans,
  }) : _featureNames = {for (final f in features) f.key: f.nameAr},
       
       _planNames = {
         for (final p in plans) ...{p.id: p.nameAr, p.key: p.nameAr},
       };

  final Map<String, String> _featureNames;
  final Map<String, String> _planNames;

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// What the change was *about*, in one phrase.
  String subject(LicenseAuditEntry entry) {
    final ref = entry.entityRef.trim();
    switch (entry.entityType) {
      case 'settings':
        
        return 'إعدادات المنصة';
      case 'feature':
      case 'override':
        return _featureNames[ref] ?? ref;
      case 'plan':
        return _planNames[ref] ?? ref;
      case 'plan_feature':
        final feature = _featureNames[ref] ?? ref;
        final plan = _planOf(entry);
        return plan == null ? feature : '$feature — باقة $plan';
      case 'license':
        return entry.officeName ?? 'ترخيص مكتب';
      default:
        if (ref.isEmpty || _uuid.hasMatch(ref)) {
          return entry.officeName ?? entry.entityLabelAr;
        }
        return ref;
    }
  }

  String? _planOf(LicenseAuditEntry entry) {
    final row = entry.newValue ?? entry.oldValue;
    final ref = row?['plan_id'] ?? row?['plan_key'];
    return ref == null ? null : _planNames['$ref'];
  }

  /// The one-line "what actually changed", used when the operator wrote no
  /// reason — an audit row with neither is a row nobody can act on.
  String? summary(LicenseAuditEntry entry) {
    if (entry.reason.trim().isNotEmpty) return entry.reason.trim();
    final rows = changes(entry);
    if (rows.isEmpty) return null;
    final first = rows.first;
    final line = first.before == null
        ? '${first.label}: ${first.after ?? '—'}'
        : '${first.label}: ${first.before} ← ${first.after ?? '—'}';
    return rows.length == 1 ? line : '$line · و${rows.length - 1} حقل آخر';
  }

  /// The changed fields, old → new.
  ///
  /// Bookkeeping columns are dropped: `updated_at` moves on every write and
  /// would put a meaningless row at the top of every single diff.
  List<AuditChange> changes(LicenseAuditEntry entry) {
    const skip = {
      'id',
      'office_id',
      'created_at',
      'updated_at',
      'created_by',
      'updated_by',
      'actor_id',
    };
    final before = entry.oldValue ?? const <String, dynamic>{};
    final after = entry.newValue ?? const <String, dynamic>{};
    final keys = <String>{...before.keys, ...after.keys}
      ..removeWhere(skip.contains);

    final rows = <AuditChange>[];
    for (final key in keys.toList()..sort()) {
      final oldValue = before[key];
      final newValue = after[key];
      if (_same(oldValue, newValue)) continue;
      rows.add((
        label: fieldLabel(key),
        before: before.containsKey(key) ? formatValue(key, oldValue) : null,
        after: after.containsKey(key) ? formatValue(key, newValue) : null,
      ));
    }
    return rows;
  }

  bool _same(Object? a, Object? b) => '$a' == '$b';

  String fieldLabel(String key) => switch (key) {
    'status' => 'الحالة',
    'plan_id' || 'plan_key' => 'الباقة',
    'value' => 'القيمة',
    'default_value' => 'القيمة الافتراضية',
    'feature_key' => 'الميزة',
    'price' => 'السعر',
    'price_monthly' => 'السعر الشهري',
    'price_yearly' => 'السعر السنوي',
    'currency' => 'العملة',
    'billing_cycle' || 'cycle' => 'الدورة',
    'auto_renew' => 'تجديد تلقائي',
    'trial_days' || 'days' => 'أيام التجربة',
    'trial_ends_at' => 'نهاية التجربة',
    'period_start' => 'بداية المدة',
    'period_end' => 'نهاية المدة',
    'expires_at' => 'ينتهي في',
    'suspended_at' => 'تاريخ الإيقاف',
    'suspended_reason' => 'سبب الإيقاف',
    'enforcement_mode' => 'وضع التطبيق',
    'is_enforced' => 'مطبَّقة بالكود',
    'is_public' => 'ظاهرة للعملاء',
    'name_ar' => 'الاسم',
    'name_en' => 'الاسم (إنجليزي)',
    'description_ar' => 'الوصف',
    'tagline_ar' => 'العبارة التعريفية',
    'category_key' => 'التصنيف',
    'value_type' => 'نوع القيمة',
    'unit_ar' => 'الوحدة',
    'sort_order' => 'الترتيب',
    'notes' => 'ملاحظات',
    'reason' => 'السبب',
    'contract_ref' => 'مرجع العقد',
    'licensing_hold' => 'حجب السوق',
    'revision' => 'المراجعة',
    'key' => 'المفتاح',
    _ => key,
  };

  String formatValue(String key, Object? value) {
    if (value == null) return '—';
    if (key == 'plan_id' || key == 'plan_key') {
      return _planNames['$value'] ?? '$value';
    }
    if (key == 'feature_key') return _featureNames['$value'] ?? '$value';
    if (key == 'value' || key == 'default_value') {
      return FeatureValue.label(value);
    }
    if (value is bool) return value ? 'نعم' : 'لا';
    if (value is num) return '$value';
    if (value is Map || value is List) return '$value';

    final text = '$value';
    if (text.isEmpty) return '—';
    if (key == 'status') return _licenseStatus[text] ?? text;
    if (key == 'enforcement_mode') return _enforcementMode[text] ?? text;
    if (key == 'billing_cycle' || key == 'cycle') {
      return _billingCycle[text] ?? text;
    }
    if (key == 'licensing_hold') return _hold[text] ?? text;
    if (text.length >= 10 && text.contains('-')) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) return licensingDate(parsed);
    }
    return text;
  }

  static const _licenseStatus = {
    'active': 'نشط',
    'trialing': 'تجريبي',
    'past_due': 'متأخر',
    'grace': 'مهلة',
    'suspended': 'موقوف',
    'cancelled': 'ملغى',
    'expired': 'منتهٍ',
  };

  static const _enforcementMode = {
    'off': 'معطّل',
    'shadow': 'ظل',
    'enforcing': 'مفعّل',
  };

  static const _billingCycle = {
    'monthly': 'شهرية',
    'yearly': 'سنوية',
    'custom': 'عقد مخصص',
    'free': 'مجانية',
  };

  static const _hold = {
    'delisted': 'محجوب عن العملاء',
    'read_only': 'قراءة فقط',
    'none': 'لا يوجد',
  };
}

/// One field that changed. A null [before] means the field did not exist before
/// (a creation), a null [after] means it is gone (a deletion) — which is a
/// different statement from "changed to empty".
typedef AuditChange = ({String label, String? before, String? after});

/// The colour an action is read in. Creations and restorations are green,
/// removals and suspensions are red, and concessions — an override, a changed
/// limit — are amber: they are neither routine nor a failure, and colouring
/// them like either is how a console stops being trusted.
AppStatusTone auditTone(String action) => switch (action) {
  'created' ||
  'enabled' ||
  'restored' ||
  'renewed' ||
  'trial_started' ||
  'trial_extended' => AppStatusTone.success,
  'deleted' || 'disabled' || 'suspended' || 'cancelled' => AppStatusTone.error,
  'override_created' ||
  'override_removed' ||
  'limit_changed' => AppStatusTone.warning,
  'plan_changed' => AppStatusTone.special,
  _ => AppStatusTone.info,
};

IconData auditIcon(String action) => switch (action) {
  'created' => Icons.add_circle_outline_rounded,
  'updated' => Icons.edit_outlined,
  'deleted' => Icons.delete_outline_rounded,
  'enabled' => Icons.toggle_on_outlined,
  'disabled' => Icons.toggle_off_outlined,
  'plan_changed' => DashboardIcons.plans,
  'limit_changed' => DashboardIcons.usage,
  'override_created' => DashboardIcons.locked,
  'override_removed' => Icons.lock_open_rounded,
  'trial_started' || 'trial_extended' => DashboardIcons.time,
  'renewed' => Icons.autorenew_rounded,
  'suspended' => Icons.pause_circle_outline_rounded,
  'restored' => Icons.play_circle_outline_rounded,
  'cancelled' => Icons.cancel_outlined,
  _ => DashboardIcons.audit,
};

/// `14:32` — the clock half of [licensingDate]. An audit log without times
/// cannot answer "what happened first", which is most of what it is for.
String auditTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String auditDateTime(DateTime? value) => value == null
    ? '—'
    : '${licensingDate(value)} — ${auditTime(value)}:'
          '${value.toLocal().second.toString().padLeft(2, '0')}';

/// "قبل ٥ دقائق" — how fresh the trail is, at a glance.
String auditRelative(DateTime? value) {
  if (value == null) return '—';
  final gap = DateTime.now().difference(value.toLocal());
  if (gap.isNegative || gap.inMinutes < 1) return 'الآن';
  if (gap.inMinutes < 60) return 'قبل ${gap.inMinutes} دقيقة';
  if (gap.inHours < 24) return 'قبل ${gap.inHours} ساعة';
  if (gap.inDays < 30) return 'قبل ${gap.inDays} يوم';
  return licensingDate(value);
}

const _weekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

/// A day's worth of the trail.
typedef AuditDay = ({DateTime day, List<LicenseAuditEntry> entries});

/// Groups the trail by calendar day, newest first, preserving the server's
/// ordering inside each day.
List<AuditDay> groupAuditByDay(Iterable<LicenseAuditEntry> entries) {
  final buckets = <DateTime, List<LicenseAuditEntry>>{};
  for (final entry in entries) {
    final local = entry.createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    buckets.putIfAbsent(day, () => []).add(entry);
  }
  final days = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final day in days) (day: day, entries: buckets[day]!)];
}

/// Day separator: the operator's anchor while scanning a long trail.
class AuditDayHeader extends StatelessWidget {
  const AuditDayHeader({super.key, required this.day, required this.count});

  final DateTime day;
  final int count;

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final gap = today.difference(day).inDays;
    if (gap == 0) return 'اليوم';
    if (gap == 1) return 'أمس';
    return _weekdays[day.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.medium,
        bottom: AppSpacing.small,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            _label,
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            licensingDate(day),
            style: text.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Divider(height: 1, color: DashboardColors.divider(context)),
          ),
          const SizedBox(width: AppSpacing.medium),
          Text(
            '$count تغيير',
            style: text.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// One decision in the trail.
///
/// The row answers *what changed* in words; the values behind it — the before
/// and after, the raw reference, the exact second — live one tap away, so a
/// hundred rows stay scannable without the evidence being thrown away.
class AuditEntryTile extends StatefulWidget {
  const AuditEntryTile({super.key, required this.entry, required this.labels});

  final LicenseAuditEntry entry;
  final AuditLabels labels;

  @override
  State<AuditEntryTile> createState() => _AuditEntryTileState();
}

class _AuditEntryTileState extends State<AuditEntryTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final labels = widget.labels;
    final text = Theme.of(context).textTheme;
    final tone = context.status(auditTone(entry.action));
    final changes = labels.changes(entry);
    final summary = labels.summary(entry);
    final office = entry.officeName?.trim();
    final actor = entry.actorLabel.trim().isEmpty
        ? 'النظام'
        : entry.actorLabel.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;

        final meta = <String>[
          if (compact && office != null && office.isNotEmpty) office,
          if (compact) actor,
        ];

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.small,
                horizontal: AppSpacing.small,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            auditTime(entry.createdAt),
                            style: text.labelSmall?.copyWith(
                              color: DashboardColors.mutedInk(context),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: tone.tint,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          auditIcon(entry.action),
                          size: 16,
                          color: tone.ink,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppSpacing.small,
                              runSpacing: AppSpacing.xSmall,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _ActionPill(
                                  label: entry.actionLabelAr,
                                  tint: tone.tint,
                                  ink: tone.ink,
                                ),
                                Text(
                                  labels.subject(entry),
                                  style: text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  entry.entityLabelAr,
                                  style: text.labelSmall?.copyWith(
                                    color: DashboardColors.faintInk(context),
                                  ),
                                ),
                              ],
                            ),
                            if (summary != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall?.copyWith(
                                    color: DashboardColors.mutedInk(context),
                                  ),
                                ),
                              ),
                            if (meta.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  meta.join(' · '),
                                  style: text.labelSmall?.copyWith(
                                    color: DashboardColors.faintInk(context),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: AppSpacing.medium),
                        SizedBox(
                          width: 150,
                          child: Text(
                            office == null || office.isEmpty
                                
                                ? 'المنصة'
                                : office,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: office == null || office.isEmpty
                                  ? DashboardColors.faintInk(context)
                                  : DashboardColors.mutedInk(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        SizedBox(
                          width: 110,
                          child: Text(
                            actor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(
                              color: DashboardColors.mutedInk(context),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.xSmall),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: AppTokens.motionBase,
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: DashboardColors.faintInk(context),
                        ),
                      ),
                    ],
                  ),
                  
                  AnimatedSize(
                    duration: AppTokens.motionBase,
                    alignment: Alignment.topCenter,
                    child: _open
                        ? _AuditDetail(entry: entry, changes: changes)
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.tint,
    required this.ink,
  });

  final String label;
  final Color tint;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// The evidence: what the values were, what they became, and the raw row behind
/// the sentence above it.
class _AuditDetail extends StatelessWidget {
  const _AuditDetail({required this.entry, required this.changes});

  final LicenseAuditEntry entry;
  final List<AuditChange> changes;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      
      margin: const EdgeInsetsDirectional.only(
        top: AppSpacing.small,
        start: 84,
        end: 24,
      ),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.reason.trim().isNotEmpty) ...[
            _DetailLine(label: 'السبب', value: entry.reason.trim()),
            const SizedBox(height: AppSpacing.small),
          ],
          if (changes.isEmpty)
            Text(
              'لم تُسجَّل قيم لهذا التغيير.',
              style: text.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            )
          else
            for (final change in changes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
                child: _ChangeRow(change: change),
              ),
          const SizedBox(height: AppSpacing.small),
          Divider(height: 1, color: DashboardColors.divider(context)),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.xSmall,
            children: [
              _MetaChip(label: 'رقم السجل', value: '#${entry.id}'),
              _MetaChip(
                label: 'التوقيت',
                value: auditDateTime(entry.createdAt),
              ),
              _MetaChip(label: 'النوع', value: entry.entityType),
              if (entry.entityRef.trim().isNotEmpty)
                _MetaChip(label: 'المرجع', value: entry.entityRef.trim()),
              _MetaChip(
                label: 'المنفِّذ',
                value: entry.actorLabel.trim().isEmpty
                    ? 'النظام'
                    : entry.actorLabel.trim(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change});

  final AuditChange change;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              change.label,
              style: text.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (change.before != null)
                _ValueBox(value: change.before!, muted: true),
              if (change.before != null && change.after != null)
                
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: DashboardColors.faintInk(context),
                ),
              if (change.after != null)
                _ValueBox(value: change.after!, accent: scheme.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.value, this.muted = false, this.accent});

  final String value;
  final bool muted;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? DashboardColors.mutedInk(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: muted ? DashboardColors.nested(context) : color.withAlpha(22),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        value,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: muted ? FontWeight.normal : FontWeight.w700,
          decoration: muted ? TextDecoration.lineThrough : null,
          decorationColor: DashboardColors.faintInk(context),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
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
            style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RichText(
      text: TextSpan(
        style: text.labelSmall?.copyWith(
          color: DashboardColors.faintInk(context),
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: text.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
