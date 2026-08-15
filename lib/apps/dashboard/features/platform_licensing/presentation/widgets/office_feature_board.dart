import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../../domain/entities/office_license.dart';
import 'licensing_layout.dart';
import 'licensing_widgets.dart';

/// «الميزات والحدود» — everything the platform sells, switched on or off for
/// one office, with the numeric ceilings editable in place.
///
/// **Why this exists.** Changing one thing for one office used to mean: open
/// التراخيص, find the office, open it, reach the الاستثناءات tab, press
/// «استثناء», find the feature in a dropdown of forty-seven, set a value, type
/// eight characters, save — and repeat the whole loop for the second thing.
/// Nothing on that path ever showed the operator *what this office currently
/// has*, which is the question they opened the screen with. The board answers
/// that question first and makes the change a switch.
///
/// **It is a draft, not a live switch.** Every control writes into an edit
/// buffer the screen owns; nothing reaches the server until «تطبيق». That is
/// deliberate on a screen where one office's whole configuration is one press
/// away from changing: the operator sees the full set of changes, states the
/// reason once for the decision they actually made, and applies them together.
///
/// **It never pretends.** A feature the platform has killed globally, or one
/// held down by the licence's own status, renders disabled and says which rung
/// of the ladder is holding it — because a switch that silently snaps back is
/// worse than one that refuses. A feature with no code behind it yet carries
/// «غير مفعّلة بعد», so nobody sells a customer a switch that does nothing.
class OfficeFeatureBoard extends StatefulWidget {
  const OfficeFeatureBoard({
    super.key,
    required this.detail,
    required this.catalog,
    required this.usage,
    required this.draft,
    required this.generation,
    required this.onEdit,
    required this.onDropEdit,
  });

  final OfficeLicenseDetail detail;
  final FeatureCatalog catalog;

  /// This office's usage row, when the console has loaded it. It carries the
  /// meter kind the resolved features do not, and is the fallback source of
  /// `used` counts.
  final OfficeUsageRow? usage;

  /// The unsaved edit buffer, keyed by feature key. Owned by the screen so that
  /// leaving the office can discard it — a draft owned by this widget is a
  /// draft the navigation can only lose silently.
  final Map<String, OfficeFeatureEdit> draft;

  /// Bumped by the screen whenever the buffer is discarded or reloaded, so the
  /// text fields inside rebuild from the new values instead of keeping the
  /// characters the operator typed into the previous draft.
  final int generation;

  final void Function(OfficeFeatureEdit edit) onEdit;
  final ValueChanged<String> onDropEdit;

  @override
  State<OfficeFeatureBoard> createState() => _OfficeFeatureBoardState();
}

/// The narrowing axes of the board, in the order an operator reaches for them.
enum _Lens { all, enabled, disabled, limits, exceptions }

/// What an edit buffer actually amounts to: the edits worth sending, and a
/// sentence for each.
///
/// Computed by [resolveOfficeFeatureChanges] rather than by either the board or
/// the save bar, so the rows highlighted as unsaved and the changes the save bar
/// counts can never be two different sets.
class OfficeFeatureChanges {
  const OfficeFeatureChanges({required this.edits, required this.summary});

  static const none = OfficeFeatureChanges(edits: [], summary: []);

  final List<OfficeFeatureEdit> edits;
  final List<String> summary;

  Set<String> get keys => {for (final edit in edits) edit.featureKey};
  bool get isEmpty => edits.isEmpty;
  bool get isNotEmpty => edits.isNotEmpty;
}

/// Reduces an edit buffer to the changes that would actually change something.
///
/// A switch flipped and flipped back is not a change, and neither is a reset on
/// a feature that has no override to remove. Dropping both here is what keeps
/// «٣ تغييرات غير محفوظة» honest — a save bar that counts gestures instead of
/// decisions teaches the operator to ignore it.
OfficeFeatureChanges resolveOfficeFeatureChanges({
  required OfficeLicenseDetail detail,
  required FeatureCatalog catalog,
  required Map<String, OfficeFeatureEdit> draft,
}) {
  if (draft.isEmpty) return OfficeFeatureChanges.none;

  final features = {for (final f in catalog.features) f.key: f};
  final overrides = {
    for (final entry in detail.overrides)
      if (!entry.expired) entry.featureKey: entry,
  };

  final edits = <OfficeFeatureEdit>[];
  final summary = <String>[];

  for (final edit in draft.values) {
    final feature = features[edit.featureKey];
    if (feature == null) continue;
    final unit = feature.unitAr;
    final override = overrides[edit.featureKey];
    final effective =
        detail.entitlements.features[edit.featureKey]?.value ??
        feature.defaultValue;

    if (edit.isReset) {
      if (override == null) continue;
      edits.add(edit);
      summary.add(
        '${feature.nameAr}: يعود إلى قيمة الباقة '
        '(${FeatureValue.label(override.planValue, unit: unit)})',
      );
      continue;
    }

    if (_sameValue(edit.value, effective)) continue;
    edits.add(edit);
    summary.add(
      '${feature.nameAr}: من ${FeatureValue.label(effective, unit: unit)} '
      'إلى ${FeatureValue.label(edit.value, unit: unit)}',
    );
  }

  return OfficeFeatureChanges(edits: edits, summary: summary);
}

/// One catalog feature joined to everything this office knows about it.
typedef _BoardRow = ({
  CatalogFeature feature,
  ResolvedFeature? resolved,
  FeatureOverride? override,
  UsageMetric? metric,
});

class _OfficeFeatureBoardState extends State<OfficeFeatureBoard> {
  String _query = '';
  String? _category;
  _Lens _lens = _Lens.all;

  List<_BoardRow> get _rows {
    final entitlements = widget.detail.entitlements;
    final metrics = {
      for (final metric in widget.usage?.metrics ?? const <UsageMetric>[])
        metric.key: metric,
    };
    final overrides = {
      for (final entry in widget.detail.overrides)
        if (!entry.expired) entry.featureKey: entry,
    };

    return [
      for (final feature in widget.catalog.features)
        if (feature.status != 'hidden')
          (
            feature: feature,
            resolved: entitlements.features[feature.key],
            override: overrides[feature.key],
            metric: metrics[feature.key],
          ),
    ];
  }

  Object? _effective(_BoardRow row) =>
      row.resolved?.value ?? row.feature.defaultValue;

  String _source(_BoardRow row) => row.resolved?.source ?? 'default';

  /// What the row shows right now — the pending edit when there is one, the
  /// resolver's answer otherwise.
  Object? _shown(_BoardRow row) {
    final edit = widget.draft[row.feature.key];
    if (edit == null) return _effective(row);
    if (edit.isReset) {
      return row.override?.planValue ?? row.feature.defaultValue;
    }
    return edit.value;
  }

  /// A feature the platform killed, or one the licence's own status is holding
  /// down, cannot be granted to a single office — the resolver would overrule
  /// the override on the next read.
  bool _isLocked(_BoardRow row) =>
      row.feature.isKillSwitched ||
      const {'kill_switch', 'license_hold'}.contains(_source(row));

  bool _matches(_BoardRow row) {
    if (_category != null && row.feature.categoryKey != _category) return false;

    switch (_lens) {
      case _Lens.enabled:
        if (!FeatureValue.truthy(_shown(row))) return false;
      case _Lens.disabled:
        if (FeatureValue.truthy(_shown(row))) return false;
      case _Lens.limits:
        if (!row.feature.isLimit) return false;
      case _Lens.exceptions:
        if (row.override == null && _source(row) != 'override') return false;
      case _Lens.all:
        break;
    }

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return row.feature.nameAr.contains(q) ||
        row.feature.key.toLowerCase().contains(q) ||
        row.feature.nameEn.toLowerCase().contains(q) ||
        row.feature.descriptionAr.contains(q);
  }

  void _set(_BoardRow row, Object? value) => widget.onEdit(
    OfficeFeatureEdit.set(
      featureKey: row.feature.key,
      nameAr: row.feature.nameAr,
      value: value,
    ),
  );

  void _reset(_BoardRow row) => widget.onEdit(
    OfficeFeatureEdit.reset(
      featureKey: row.feature.key,
      nameAr: row.feature.nameAr,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final rows = _rows;
    final visible = rows.where(_matches).toList();

    // The same reduction the save bar shows, so a highlighted row and a counted
    // change are always the same thing.
    final dirtyKeys = resolveOfficeFeatureChanges(
      detail: widget.detail,
      catalog: widget.catalog,
      draft: widget.draft,
    ).keys;

    final on = rows.where((r) => FeatureValue.truthy(_shown(r))).length;
    final exceptions = rows.where((r) => r.override != null).length;
    final overLimit = widget.detail.overLimits.length;

    final grouped = <String, List<_BoardRow>>{};
    for (final row in visible) {
      grouped.putIfAbsent(row.feature.categoryKey, () => []).add(row);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.feature.sortOrder.compareTo(b.feature.sortOrder));
    }
    final orderedKeys = [
      for (final category in widget.catalog.categories)
        if (grouped.containsKey(category.key)) category.key,
      ...grouped.keys.where(
        (key) => !widget.catalog.categories.any((c) => c.key == key),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BoardNotices(detail: widget.detail),
        LicensingStatStrip(
          stats: [
            LicensingStat(
              icon: DashboardIcons.featureCatalog,
              value: '$on',
              label: 'ميزة مفعّلة',
              color: scheme.secondary,
            ),
            LicensingStat(
              icon: Icons.toggle_off_outlined,
              value: '${rows.length - on}',
              label: 'ميزة متوقفة',
            ),
            // `locked` is the console's mark for an exception everywhere else;
            // keeping it here is what makes the strip readable at a glance by
            // someone who has only ever used التراخيص.
            LicensingStat(
              icon: DashboardIcons.locked,
              value: '$exceptions',
              label: 'استثناء لهذا المكتب',
              color: exceptions > 0 ? scheme.tertiary : null,
            ),
            LicensingStat(
              icon: DashboardIcons.usage,
              value: '$overLimit',
              label: 'حد متجاوَز',
              color: overLimit > 0 ? scheme.error : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        _BoardToolbar(
          rows: rows,
          query: _query,
          category: _category,
          lens: _lens,
          categories: widget.catalog.categories,
          visibleCount: visible.length,
          isEnabled: (row) => FeatureValue.truthy(_shown(row)),
          hasException: (row) => row.override != null,
          onQuery: (q) => setState(() => _query = q),
          onCategory: (c) => setState(() => _category = c),
          onLens: (l) => setState(() => _lens = l),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (visible.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: DashboardEmptyState(
              icon: DashboardIcons.featureCatalog,
              title: 'لا ميزة تطابق ما اخترته',
              message: switch (_lens) {
                _Lens.exceptions =>
                  'هذا المكتب يتبع باقته بالكامل — لا استثناء واحد عليه.',
                _Lens.limits => 'لا توجد ميزات ذات حد رقمي في هذا التصنيف.',
                _ => 'جرّب اسمًا آخر، أو أزل التصفية.',
              },
              action: TextButton(
                onPressed: () => setState(() {
                  _query = '';
                  _category = null;
                  _lens = _Lens.all;
                }),
                child: const Text('عرض كل الميزات'),
              ),
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final key in orderedKeys)
                  _CategoryBlock(
                    name: widget.catalog.categoryName(key),
                    rows: grouped[key]!,
                    dirtyCount: grouped[key]!
                        .where((row) => dirtyKeys.contains(row.feature.key))
                        .length,
                    children: [
                      for (final row in grouped[key]!)
                        _FeatureRow(
                          key: ValueKey(
                            '${widget.generation}:${row.feature.key}',
                          ),
                          row: row,
                          planNameAr: widget.detail.license.planNameAr,
                          shown: _shown(row),
                          effective: _effective(row),
                          source: _source(row),
                          isDirty: dirtyKeys.contains(row.feature.key),
                          isLocked: _isLocked(row),
                          isPending: widget.draft.containsKey(row.feature.key),
                          willReset:
                              widget.draft[row.feature.key]?.isReset ?? false,
                          onChanged: (value) => _set(row, value),
                          onReset: () => _reset(row),
                          onDropEdit: () => widget.onDropEdit(row.feature.key),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'كل تغيير هنا يُسجَّل باسمك وبسببه في سجل التغييرات، ويسري على المكتب '
          'فور الحفظ. رفع حدٍّ لا يمسّ ما هو قائم، وخفضه لا يحذف شيئًا — يمنع '
          'الإنشاء الجديد فقط.',
          style: text.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

/// `40 == 40.0` and `true == true`; anything else is a real difference.
bool _sameValue(Object? a, Object? b) {
  if (a is num && b is num) return a == b;
  return a == b;
}

/// The two facts that change what every switch on this board means, and only
/// when they are true.
class _BoardNotices extends StatelessWidget {
  const _BoardNotices({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notices = <Widget>[
      if (detail.entitlements.enforcementMode != 'enforcing')
        LicensingNotice(
          icon: DashboardIcons.attention,
          color: scheme.tertiary,
          message:
              'تطبيق الحدود معطّل على مستوى المنصة الآن، فما تضبطه هنا يُحفَظ '
              'ويُسجَّل ولا يمنع شيئًا حتى يُفعَّل الوضع من شاشة التراخيص.',
        ),
      if (detail.licensingHold != 'none')
        LicensingNotice(
          icon: DashboardIcons.locked,
          color: scheme.error,
          message: detail.licensingHold == 'delisted'
              ? 'ترخيص المكتب موقوف: هو الآن في وضع القراءة فقط ومحجوب عن '
                    'العملاء، وحالة الترخيص تتقدّم على أي ميزة تُفعِّلها هنا.'
              : 'ترخيص المكتب في وضع القراءة فقط، وحالة الترخيص تتقدّم على أي '
                    'ميزة تُفعِّلها هنا.',
        ),
    ];

    if (notices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, notice) in notices.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.small),
            notice,
          ],
        ],
      ),
    );
  }
}

/// Search, one labelled category selector, and the five questions this board is
/// actually opened with.
class _BoardToolbar extends StatelessWidget {
  const _BoardToolbar({
    required this.rows,
    required this.query,
    required this.category,
    required this.lens,
    required this.categories,
    required this.visibleCount,
    required this.isEnabled,
    required this.hasException,
    required this.onQuery,
    required this.onCategory,
    required this.onLens,
  });

  final List<_BoardRow> rows;
  final String query;
  final String? category;
  final _Lens lens;
  final List<FeatureCategory> categories;
  final int visibleCount;
  final bool Function(_BoardRow) isEnabled;
  final bool Function(_BoardRow) hasException;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onCategory;
  final ValueChanged<_Lens> onLens;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final counts = {
      _Lens.all: rows.length,
      _Lens.enabled: rows.where(isEnabled).length,
      _Lens.disabled: rows.where((r) => !isEnabled(r)).length,
      _Lens.limits: rows.where((r) => r.feature.isLimit).length,
      _Lens.exceptions: rows.where(hasException).length,
    };
    const labels = {
      _Lens.all: 'الكل',
      _Lens.enabled: 'المفعّلة',
      _Lens.disabled: 'المتوقفة',
      _Lens.limits: 'الحدود الرقمية',
      _Lens.exceptions: 'الاستثناءات',
    };

    final present = categories
        .where((c) => rows.any((r) => r.feature.categoryKey == c.key))
        .toList();

    return LicensingToolbar(
      search: DebouncedSearchField(
        initialValue: query,
        hintText: 'ابحث في الميزات',
        onChanged: onQuery,
      ),
      filters: [
        for (final entry in labels.entries)
          FilterChip(
            label: Text('${entry.value} (${counts[entry.key]})'),
            selected: lens == entry.key,
            onSelected: (_) => onLens(entry.key),
          ),
        // Named, not a bare chip: the categories are the one axis whose values
        // ("التشغيل", "المالية") do not announce which question they answer.
        _CategoryPicker(
          categories: present,
          selected: category,
          onChanged: onCategory,
        ),
      ],
      trailing: Text(
        'يُعرض $visibleCount من ${rows.length}',
        style: text.labelMedium?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<FeatureCategory> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.small),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          isDense: true,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          hint: const Text('كل التصنيفات'),
          style: theme.textTheme.labelLarge,
          items: [
            const DropdownMenuItem(value: null, child: Text('كل التصنيفات')),
            for (final category in categories)
              DropdownMenuItem(
                value: category.key,
                child: Text(category.nameAr),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// A category heading and its rows, sharing one card with its neighbours.
///
/// Not a collapsible section, for the same reason the plan editor's blocks are
/// not: this board is swept, and a column of folded headings turns "review what
/// this office has" into fifteen presses before the first answer.
class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.name,
    required this.rows,
    required this.dirtyCount,
    required this.children,
  });

  final String name;
  final List<_BoardRow> rows;
  final int dirtyCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
          color: DashboardColors.well(context),
          child: Row(
            children: [
              Icon(
                DashboardIcons.featureCatalog,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                dirtyCount == 0
                    ? '${rows.length} ميزة'
                    : '${rows.length} ميزة · $dirtyCount غير محفوظ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: dirtyCount == 0
                      ? DashboardColors.mutedInk(context)
                      : theme.colorScheme.tertiary,
                  fontWeight: dirtyCount == 0 ? null : FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

/// One feature: what it is, where its current value came from, and the control
/// that changes it.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    super.key,
    required this.row,
    required this.planNameAr,
    required this.shown,
    required this.effective,
    required this.source,
    required this.isDirty,
    required this.isLocked,
    required this.isPending,
    required this.willReset,
    required this.onChanged,
    required this.onReset,
    required this.onDropEdit,
  });

  final _BoardRow row;
  final String planNameAr;
  final Object? shown;
  final Object? effective;
  final String source;
  final bool isDirty;
  final bool isLocked;
  final bool isPending;
  final bool willReset;
  final ValueChanged<Object?> onChanged;
  final VoidCallback onReset;
  final VoidCallback onDropEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final feature = row.feature;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: isDirty ? scheme.tertiary.withAlpha(14) : null,
        border: Border(
          top: BorderSide(color: DashboardColors.divider(context)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 10,
            child: isDirty
                ? Tooltip(
                    message:
                        'غير محفوظ — الحالي: '
                        '${FeatureValue.label(effective, unit: feature.unitAr)}',
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: scheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        feature.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!feature.isEnforced) ...[
                      const SizedBox(width: AppSpacing.small),
                      const EnforcementBadge(isEnforced: false),
                    ],
                    if (feature.status == 'deprecated') ...[
                      const SizedBox(width: AppSpacing.xSmall),
                      StatusChip(
                        label: 'مهجورة',
                        color: scheme.outline.withAlpha(24),
                        textColor: scheme.outline,
                      ),
                    ],
                    const SizedBox(width: AppSpacing.small),
                    FeatureSourceChip(
                      source: source,
                      blockedBy: row.resolved?.blockedBy,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _RowStory(
                  row: row,
                  planNameAr: planNameAr,
                  source: source,
                  isLocked: isLocked,
                  willReset: willReset,
                  onReset: onReset,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 190),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _FeatureControl(
                feature: feature,
                value: shown,
                enabled: !isLocked && !willReset,
                onChanged: onChanged,
              ),
            ),
          ),
          IconButton(
            tooltip: 'تراجع عن التعديل غير المحفوظ',
            icon: const Icon(Icons.undo_rounded, size: 18),
            onPressed: isPending ? onDropEdit : null,
          ),
        ],
      ),
    );
  }
}

/// The one line under a feature's name: where its value came from, what it is
/// costing the office, and the way back to the plan.
class _RowStory extends StatelessWidget {
  const _RowStory({
    required this.row,
    required this.planNameAr,
    required this.source,
    required this.isLocked,
    required this.willReset,
    required this.onReset,
  });

  final _BoardRow row;
  final String planNameAr;
  final String source;
  final bool isLocked;
  final bool willReset;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: DashboardColors.mutedInk(context),
    );

    if (willReset) {
      return Text(
        'سيعود إلى قيمة الباقة عند الحفظ.',
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.tertiary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    // The catalog's own status is read first: a feature disabled platform-wide
    // is refused here whether or not this office's resolved document happens to
    // name the kill switch as the rung that answered.
    final origin = row.feature.isKillSwitched
        ? 'موقوفة على مستوى المنصة — لا يمكن تفعيلها لمكتب واحد.'
        : switch (source) {
            'kill_switch' =>
              'موقوفة على مستوى المنصة — لا يمكن تفعيلها لمكتب واحد.',
            'license_hold' => 'حالة الترخيص تحجبها الآن.',
            'override' => 'استثناء لهذا المكتب.',
            'plan' =>
              planNameAr.isEmpty ? 'من باقة المكتب.' : 'من باقة «$planNameAr».',
            _ => 'الافتراضي في الكتالوج.',
          };

    final usage = _usageLabel();

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          origin,
          style: isLocked ? muted?.copyWith(color: scheme.error) : muted,
        ),
        if (usage != null)
          Text(
            usage.$1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: usage.$2
                  ? scheme.error
                  : DashboardColors.mutedInk(context),
              fontWeight: usage.$2 ? FontWeight.w800 : null,
            ),
          ),
        if (row.override case final entry?) ...[
          Text('السبب: ${entry.reason}', style: muted),
          if (entry.expiresAt != null)
            Text('ينتهي ${licensingDate(entry.expiresAt)}', style: muted),
          _InlineAction(
            label: 'إرجاع لقيمة الباقة',
            icon: Icons.settings_backup_restore_rounded,
            onPressed: onReset,
          ),
        ],
      ],
    );
  }

  /// «مستخدَم ١٢ من ٤٠», and whether that is an overage. Limits only: a count
  /// under a switch means nothing.
  (String, bool)? _usageLabel() {
    if (!row.feature.isLimit) return null;
    final used = row.metric?.used ?? row.resolved?.used;
    if (used == null) return null;

    final limit = row.metric?.limit ?? row.resolved?.limit;
    if (limit == null) return ('مستخدَم $used — بلا سقف', false);
    if (used > limit) {
      return ('مستخدَم $used من $limit — تجاوز ${used - limit}', true);
    }
    return ('مستخدَم $used من $limit', false);
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.labelSmall,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// The typed control for one feature, sized for a board rather than a dialog.
///
/// It is the board's own rather than the shared [FeatureValueField] because the
/// two are answering different questions: the plan editor sets a template value
/// with no unit and no ceiling in sight, while this one sits beside a live
/// usage count and must say «سائق» next to the number the operator is typing.
class _FeatureControl extends StatelessWidget {
  const _FeatureControl({
    required this.feature,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final CatalogFeature feature;
  final Object? value;
  final bool enabled;
  final ValueChanged<Object?> onChanged;

  /// A stable handle on this feature's control, whatever type it turns out to
  /// be. The row around it is rebuilt wholesale when the buffer is dropped, so
  /// this key is about *identity*, not state — it is what lets a test, or a
  /// future "jump to this feature", address one row's control by name.
  Key get _controlKey => ValueKey('${feature.key}:control');

  @override
  Widget build(BuildContext context) {
    switch (feature.valueType) {
      case 'boolean':
        return Switch(
          key: _controlKey,
          value: FeatureValue.truthy(value),
          onChanged: enabled ? onChanged : null,
        );

      case 'limit':
        final unlimited = FeatureValue.isUnlimited(value);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!unlimited)
              SizedBox(
                width: feature.unitAr.isEmpty ? 96 : 128,
                child: TextFormField(
                  key: _controlKey,
                  initialValue: value is num ? '$value' : '',
                  enabled: enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixText: feature.unitAr.isEmpty ? null : feature.unitAr,
                  ),
                  onChanged: (raw) {
                    final parsed = int.tryParse(_westernDigits(raw.trim()));
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
        final current = value is String && feature.allowedValues.contains(value)
            ? value as String
            : (feature.defaultValue is String
                  ? feature.defaultValue as String
                  : feature.allowedValues.firstOrNull);
        return DropdownButton<String>(
          key: _controlKey,
          value: current,
          isDense: true,
          items: [
            for (final allowed in feature.allowedValues)
              DropdownMenuItem(value: allowed, child: Text(allowed)),
          ],
          onChanged: enabled ? onChanged : null,
        );

      default:
        return SizedBox(
          width: 180,
          child: TextFormField(
            key: _controlKey,
            initialValue: value == null ? '' : '$value',
            enabled: enabled,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (raw) {
              final trimmed = raw.trim();
              onChanged(int.tryParse(_westernDigits(trimmed)) ?? trimmed);
            },
          ),
        );
    }
  }
}

/// Arabic-Indic (`٠..٩`) and Extended Arabic-Indic (`۰..۹`) digits as ASCII.
///
/// The console runs RTL with an Arabic keyboard in front of it, so «٢٥» is what
/// gets typed — and `int.tryParse` returns null for it, which would have made a
/// perfectly typed limit look like an empty field.
String _westernDigits(String value) {
  const arabicIndic = 0x0660;
  const extended = 0x06F0;
  return String.fromCharCodes([
    for (final code in value.codeUnits)
      if (code >= arabicIndic && code <= arabicIndic + 9)
        code - arabicIndic + 0x30
      else if (code >= extended && code <= extended + 9)
        code - extended + 0x30
      else
        code,
  ]);
}

/// The unsaved-changes bar for the feature board.
///
/// It is the plan editor's save bar with one difference that matters: the
/// reason is **required**, because `platform_set_override` refuses anything
/// shorter than eight characters — an exception nobody explained becomes a
/// permanent unexplained exception, since in two years nobody dares remove it.
/// So the field is in the bar rather than in a modal after it, and the batch
/// asks for the reason once instead of once per switch.
class OfficeFeatureSaveBar extends StatelessWidget {
  const OfficeFeatureSaveBar({
    super.key,
    required this.edits,
    required this.summary,
    required this.reasonController,
    required this.showReasonError,
    required this.onDiscard,
    required this.onApply,
    this.onReasonChanged,
    this.isBusy = false,
    this.minReasonLength = 8,
  });

  final List<OfficeFeatureEdit> edits;

  /// One human sentence per change, at most a few — the operator confirms what
  /// they are about to do without scrolling back through the board.
  final List<String> summary;

  final TextEditingController reasonController;
  final bool showReasonError;
  final VoidCallback onDiscard;
  final VoidCallback onApply;

  /// So the refusal clears as the operator fixes it. An error message that
  /// stays red while the field it is complaining about has already been
  /// corrected is how a form teaches people to stop reading it.
  final ValueChanged<String>? onReasonChanged;

  final bool isBusy;
  final int minReasonLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = summary.take(3).toList();

    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${edits.length} ${edits.length == 1 ? 'تغيير' : 'تغييرًا'} غير محفوظ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        for (final line in shown)
          Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        if (summary.length > shown.length)
          Text(
            'و${summary.length - shown.length} أخرى',
            style: theme.textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
      ],
    );

    final reason = TextField(
      controller: reasonController,
      textInputAction: TextInputAction.done,
      onChanged: onReasonChanged,
      onSubmitted: (_) => onApply(),
      decoration: InputDecoration(
        isDense: true,
        labelText: 'السبب',
        hintText: 'مثال: عقد سنوي موقّع مع المكتب',
        border: const OutlineInputBorder(),
        errorText: showReasonError
            ? 'اكتب سببًا واضحًا ($minReasonLength أحرف على الأقل)'
            : null,
      ),
    );

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: isBusy ? null : onDiscard,
          child: const Text('تجاهل'),
        ),
        const SizedBox(width: AppSpacing.small),
        FilledButton.icon(
          onPressed: isBusy ? null : onApply,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('تطبيق'),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.tertiary.withAlpha(120), width: 1.5),
        boxShadow: DashboardColors.floatingShadow(context),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 780) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                headline,
                const SizedBox(height: AppSpacing.small),
                reason,
                const SizedBox(height: AppSpacing.small),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: buttons,
                ),
              ],
            );
          }
          return Row(
            children: [
              Icon(Icons.edit_note_rounded, color: scheme.tertiary),
              const SizedBox(width: AppSpacing.small),
              Flexible(child: headline),
              const SizedBox(width: AppSpacing.large),
              Expanded(child: reason),
              const SizedBox(width: AppSpacing.medium),
              buttons,
            ],
          );
        },
      ),
    );
  }
}
