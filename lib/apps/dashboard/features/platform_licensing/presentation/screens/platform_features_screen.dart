import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_collapsible_section.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_kpi_card.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/master_detail_layout.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';

/// كتالوج الميزات — what the platform can sell, and where each flag is real.
///
/// **List → detail, not a row of unlabelled columns.** The catalog has to answer
/// six things about a feature — its type, its default, where it is enforced,
/// what it depends on, who has it, and whether it is switched on — and an
/// operations list cannot carry six columns legibly. So the list carries only
/// what you scan by (name, key, type, and the two exceptions worth spotting from
/// across the room) and the detail pane answers the rest with every value
/// labelled.
///
/// **Finding, not browsing.** At 47 features and growing nobody scrolls to a
/// row, so search sits at the top with three narrowing axes beside it —
/// category, enforcement, status — and the KPI tiles are the shortcut into the
/// two counts operators actually chase: what is real, and what we listed but
/// never built.
class PlatformFeaturesScreen extends StatelessWidget {
  const PlatformFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        final selected = state.selectedFeature;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CatalogHeader(state: state),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: MasterDetailLayout(
                masterFlex: 2,
                detailFlex: 3,
                placeholderTitle: 'اختر ميزة لعرض تفاصيلها',
                placeholderSubtitle:
                    'أين تُطبَّق في الكود، وما الذي تتطلبه، ومن يملكها الآن، '
                    'وماذا يسقط معها إن أوقفتها.',
                master: _FeatureList(state: state),
                detail: selected == null
                    ? null
                    : _FeatureDetail(feature: selected, state: state),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Header: the counts, and the way into them ────────────────────────────────

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final scheme = Theme.of(context).colorScheme;
    final catalog = state.catalog;
    final enforcement = state.featureEnforcementFilter;

    return DashboardModuleHeader(
      icon: DashboardIcons.featureCatalog,
      title: 'كتالوج الميزات',
      subtitle: 'كل قدرة تبيعها المنصة، ونوعها، وأين تُطبَّق فعليًا في الكود.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardKpiGrid(
            children: [
              DashboardKpiCard(
                label: 'ميزات الكتالوج',
                value: '${catalog.features.length}',
                icon: DashboardIcons.featureCatalog,
                detail: state.hasFeatureFilters
                    ? 'اضغط لعرض الكل'
                    : 'كل ما يمكن بيعه',
                onTap: state.hasFeatureFilters
                    ? cubit.clearFeatureFilters
                    : null,
                tapHint: 'مسح كل عوامل التصفية',
              ),
              // The two tiles below are the screen's real entry points: an
              // operator opens this catalog to ask "what is actually real?", so
              // the number that answers it is also the control that filters to
              // it.
              DashboardKpiCard(
                label: 'مطبَّقة بكود',
                value: '${catalog.enforcedCount}',
                icon: DashboardIcons.allClear,
                color: scheme.secondary,
                detail: enforcement == 'enforced'
                    ? 'التصفية مفعّلة — اضغط للإلغاء'
                    : 'يوجد مُشغِّل أو حارس أو سياسة',
                onTap: () => cubit.filterFeaturesByEnforcement(
                  enforcement == 'enforced' ? null : 'enforced',
                ),
                tapHint: 'عرض الميزات المطبَّقة بكود فقط',
              ),
              DashboardKpiCard(
                label: 'معلنة فقط',
                value: '${catalog.declaredCount}',
                icon: DashboardIcons.attention,
                color: scheme.tertiary,
                detail: enforcement == 'declared'
                    ? 'التصفية مفعّلة — اضغط للإلغاء'
                    : 'مُدرجة ولا يوجد كود يطبّقها بعد',
                onTap: () => cubit.filterFeaturesByEnforcement(
                  enforcement == 'declared' ? null : 'declared',
                ),
                tapHint: 'عرض الميزات المعلنة فقط',
              ),
              DashboardKpiCard(
                label: 'وضع التطبيق',
                value: switch (state.settings.enforcementMode) {
                  'off' => 'معطّل',
                  'shadow' => 'وضع الظل',
                  _ => 'مفعّل',
                },
                icon: DashboardIcons.settings,
                detail: state.settings.modeLabelAr,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _FeatureFilters(state: state),
        ],
      ),
    );
  }
}

/// Search + the three narrowing axes.
class _FeatureFilters extends StatefulWidget {
  const _FeatureFilters({required this.state});

  final PlatformLicensingLoaded state;

  @override
  State<_FeatureFilters> createState() => _FeatureFiltersState();
}

class _FeatureFiltersState extends State<_FeatureFilters> {
  /// Bumped when the operator clears everything, so the search field is rebuilt
  /// around an empty controller. Keying it on "is the query empty" instead would
  /// tear the field down on the first character typed and take focus with it.
  int _searchEpoch = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<PlatformLicensingCubit>();
    final catalog = state.catalog;

    final categoryCounts = <String, int>{};
    final statusCounts = <String, int>{};
    for (final feature in catalog.features) {
      categoryCounts.update(
        feature.categoryKey,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
      statusCounts.update(feature.status, (n) => n + 1, ifAbsent: () => 1);
    }

    return DashboardCollapsibleSection.bare(
      sectionId: DashboardSectionIds.platformFeatureFilters,
      icon: Icons.filter_alt_outlined,
      title: 'البحث والتصفية',
      headerPadding: EdgeInsets.zero,
      bodyPadding: const EdgeInsets.only(top: AppSpacing.medium),
      collapsedSummary: DashboardSectionSummary(
        items: state.hasFeatureFilters
            ? state.featureFilterLabels
            : const ['كل الميزات'],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DebouncedSearchField(
                  key: ValueKey('feature-search-$_searchEpoch'),
                  initialValue: state.featureSearch,
                  hintText: 'ابحث بالاسم أو المفتاح أو الوصف',
                  onChanged: cubit.searchFeatures,
                ),
              ),
              if (state.hasFeatureFilters) ...[
                const SizedBox(width: AppSpacing.small),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _searchEpoch++);
                    cubit.clearFeatureFilters();
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('مسح التصفية'),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _FilterRow(
            label: 'التصنيف',
            children: [
              for (final category in catalog.categories)
                if ((categoryCounts[category.key] ?? 0) > 0)
                  FilterChip(
                    label: Text(
                      '${category.nameAr} (${categoryCounts[category.key]})',
                    ),
                    selected: state.featureCategoryFilter == category.key,
                    onSelected: (on) => cubit.filterFeaturesByCategory(
                      on ? category.key : null,
                    ),
                  ),
            ],
          ),
          _FilterRow(
            label: 'التطبيق',
            children: [
              FilterChip(
                label: Text('مطبَّقة بكود (${catalog.enforcedCount})'),
                selected: state.featureEnforcementFilter == 'enforced',
                onSelected: (on) =>
                    cubit.filterFeaturesByEnforcement(on ? 'enforced' : null),
              ),
              FilterChip(
                label: Text('معلنة فقط (${catalog.declaredCount})'),
                selected: state.featureEnforcementFilter == 'declared',
                onSelected: (on) =>
                    cubit.filterFeaturesByEnforcement(on ? 'declared' : null),
              ),
            ],
          ),
          _FilterRow(
            label: 'الحالة',
            children: [
              for (final status in const [
                'active',
                'hidden',
                'deprecated',
                'disabled',
              ])
                if ((statusCounts[status] ?? 0) > 0)
                  FilterChip(
                    label: Text(
                      '${_shortStatusLabel(status)} (${statusCounts[status]})',
                    ),
                    selected: state.featureStatusFilter == status,
                    onSelected: (on) =>
                        cubit.filterFeaturesByStatus(on ? status : null),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One labelled row of filter chips. The label is the fix for the old screen's
/// central failure: a control whose meaning you have to infer from its values.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Master: the list ─────────────────────────────────────────────────────────

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final groups = state.visibleFeatureGroups;
    final visibleCount = groups.fold<int>(
      0,
      (sum, g) => sum + g.features.length,
    );
    final total = state.catalog.features.length;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.medium),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Row(
                children: [
                  Icon(
                    DashboardIcons.featureCatalog,
                    size: 20,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Text(
                      'الميزات',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    // Says outright that the list is narrowed. A filtered list
                    // that looks like the whole list is how a feature gets
                    // reported missing.
                    state.hasFeatureFilters
                        ? '$visibleCount من $total'
                        : '$total ميزة',
                    style: text.bodySmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: DashboardColors.divider(context)),
            Expanded(
              child: groups.isEmpty
                  ? DashboardEmptyState(
                      icon: DashboardIcons.featureCatalog,
                      title: 'لا توجد ميزة مطابقة',
                      message: 'جرّب كلمة بحث أخرى أو ألغِ عوامل التصفية.',
                      action: state.hasFeatureFilters
                          ? TextButton.icon(
                              onPressed: cubit.clearFeatureFilters,
                              icon: const Icon(
                                Icons.filter_alt_off_outlined,
                                size: 18,
                              ),
                              label: const Text('مسح التصفية'),
                            )
                          : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.small,
                      ),
                      itemCount: groups.length,
                      separatorBuilder: (context, _) => Divider(
                        height: 1,
                        indent: AppSpacing.medium,
                        endIndent: AppSpacing.medium,
                        color: DashboardColors.divider(context),
                      ),
                      itemBuilder: (context, index) => _CategoryGroup(
                        group: groups[index],
                        selectedKey: state.selectedFeatureKey,
                        // While a filter is on, the groups are forced open:
                        // a remembered "collapsed" would hide the very rows the
                        // operator just searched for. The key rebuilds the
                        // section so it re-reads its initial state.
                        filtered: state.hasFeatureFilters,
                        onSelect: cubit.selectFeature,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.group,
    required this.selectedKey,
    required this.filtered,
    required this.onSelect,
  });

  final FeatureGroup group;
  final String? selectedKey;
  final bool filtered;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return DashboardCollapsibleSection.bare(
      key: ValueKey('feature-category-${group.key}-$filtered'),
      sectionId: filtered
          ? null
          : DashboardSectionIds.platformFeatureCategory(group.key),
      title: group.nameAr,
      headerPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.small,
      ),
      actions: [
        Text(
          '${group.features.length}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
      child: Column(
        children: [
          for (final feature in group.features)
            _FeatureRow(
              feature: feature,
              selected: feature.key == selectedKey,
              onTap: () => onSelect(feature.key),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.selected,
    required this.onTap,
  });

  final CatalogFeature feature;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final reach = [
      if (feature.planCount > 0) 'في ${feature.planCount} باقة',
      if (feature.overrideCount > 0) '${feature.overrideCount} استثناء',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withAlpha(16)
                  : DashboardColors.well(context),
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? scheme.primary.withAlpha(90)
                    : DashboardColors.border(context),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeatureDot(feature: feature),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              feature.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          // Marked by exception only. Half the catalog is
                          // healthy and a chip on every row would say nothing.
                          if (feature.isKillSwitched)
                            _RowMark(label: 'موقوفة', color: scheme.error)
                          else if (!feature.isEnforced)
                            _RowMark(
                              label: 'معلنة فقط',
                              color: scheme.tertiary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${feature.key} · ${feature.valueTypeLabelAr} · '
                        'الافتراضي ${FeatureValue.label(feature.defaultValue, unit: feature.unitAr)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                      if (reach.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          reach,
                          style: text.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The row's health at a glance: enforced and live, declared only, or killed.
class _FeatureDot extends StatelessWidget {
  const _FeatureDot({required this.feature});

  final CatalogFeature feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, message) = switch (feature) {
      final f when f.isKillSwitched => (
        scheme.error,
        'موقوفة على مستوى المنصة — ترجع إلى قيمتها الافتراضية لدى الجميع.',
      ),
      final f when !f.isEnforced => (
        scheme.tertiary,
        'معلنة فقط: مُدرجة في الكتالوج ولا يوجد كود يطبّقها بعد.',
      ),
      final f when f.status != 'active' => (scheme.outline, f.statusLabelAr),
      _ => (scheme.secondary, 'مطبَّقة بكود ونشطة.'),
    };

    return Tooltip(
      message: message,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(60),
            border: Border.all(color: color, width: 2),
          ),
        ),
      ),
    );
  }
}

/// A dense row marker — lighter than [StatusChip], which is sized for panels.
class _RowMark extends StatelessWidget {
  const _RowMark({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: AppSpacing.small),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Detail: everything the list deliberately left out ────────────────────────

class _FeatureDetail extends StatelessWidget {
  const _FeatureDetail({required this.feature, required this.state});

  final CatalogFeature feature;
  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Keyed on the feature so moving to another row starts at the top rather
      // than mid-way down the previous feature's detail.
      key: PageStorageKey('feature-detail-${feature.key}'),
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.medium),
      children: [
        _DetailHeader(feature: feature, state: state),
        const SizedBox(height: AppSpacing.medium),
        _DefinitionPanel(feature: feature),
        const SizedBox(height: AppSpacing.medium),
        _GatesPanel(feature: feature),
        const SizedBox(height: AppSpacing.medium),
        _DependenciesPanel(feature: feature),
        const SizedBox(height: AppSpacing.medium),
        _ImpactPanel(feature: feature),
        const SizedBox(height: AppSpacing.medium),
        _StatusPanel(feature: feature),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.feature, required this.state});

  final CatalogFeature feature;
  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final statusColor = _statusColor(scheme, feature.status);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: Icon(
                  DashboardIcons.featureCatalogActive,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.nameAr,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      feature.nameEn.isEmpty
                          ? feature.key
                          : '${feature.key} · ${feature.nameEn}',
                      style: text.labelSmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'إغلاق التفاصيل',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: cubit.clearFeatureSelection,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [
              StatusChip(
                label: state.catalog.categoryName(feature.categoryKey),
              ),
              StatusChip(
                label: feature.valueTypeLabelAr,
                color: scheme.surfaceContainerHighest,
                textColor: scheme.onSurfaceVariant,
              ),
              EnforcementBadge(isEnforced: feature.isEnforced),
              StatusChip(
                label: feature.statusLabelAr,
                color: statusColor.withAlpha(24),
                textColor: statusColor,
              ),
              if (!feature.isPublic)
                StatusChip(
                  label: 'غير معروضة للعملاء',
                  color: scheme.surfaceContainerHighest,
                  textColor: scheme.onSurfaceVariant,
                ),
            ],
          ),
          if (feature.descriptionAr.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              feature.descriptionAr,
              style: text.bodySmall?.copyWith(height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}

class _DefinitionPanel extends StatelessWidget {
  const _DefinitionPanel({required this.feature});

  final CatalogFeature feature;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      sectionId: DashboardSectionIds.platformFeatureDefinition,
      icon: DashboardIcons.settings,
      title: 'التعريف',
      subtitle: 'ما الذي تضبطه هذه الميزة، وبأي قيمة تبدأ.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LicensingField(label: 'المفتاح', value: feature.key),
          LicensingField(label: 'النوع', value: feature.valueTypeLabelAr),
          LicensingField(
            label: 'القيمة الافتراضية',
            value: FeatureValue.label(
              feature.defaultValue,
              unit: feature.unitAr,
            ),
          ),
          if (feature.allowedValues.isNotEmpty)
            LicensingField(
              label: 'القيم المسموحة',
              value: feature.allowedValues.join('، '),
            ),
          if (feature.isLimit)
            LicensingField(
              label: 'نوع العدّاد',
              // The distinction that decides whether deleting a row gives the
              // quota back — and the one operators get wrong on the phone.
              value: feature.isStock
                  ? 'مخزون — الحذف يعيد الحصة'
                  : 'تدفّق — الحذف لا يعيد الحصة',
            ),
          if (feature.meterPeriod != null && feature.meterPeriod!.isNotEmpty)
            LicensingField(label: 'دورة العدّاد', value: feature.meterPeriod!),
          LicensingField(
            label: 'العرض للعملاء',
            value: feature.isPublic
                ? 'تظهر في عرض الباقات'
                : 'داخلية — بالتعيين فقط',
          ),
        ],
      ),
    );
  }
}

class _GatesPanel extends StatelessWidget {
  const _GatesPanel({required this.feature});

  final CatalogFeature feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DashboardPanel(
      sectionId: DashboardSectionIds.platformFeatureGates,
      icon: DashboardIcons.licenses,
      title: 'أين تُطبَّق',
      subtitle: 'المواضع التي يفرض فيها الكود هذه الميزة فعليًا.',
      child: feature.gates.isEmpty
          ? _Notice(
              color: scheme.tertiary,
              icon: DashboardIcons.attention,
              // The honest answer, and the reason the badge exists at all.
              message:
                  'لا يوجد كود يطبّق هذه الميزة بعد. يمكن إدراجها في باقة، '
                  'لكنها لن تغيّر أي سلوك لدى المكاتب.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final gate in feature.gates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.small),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(label: gate.kindLabelAr),
                        const SizedBox(width: AppSpacing.small),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gate.ref,
                                style: text.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (gate.note.isNotEmpty)
                                Text(
                                  gate.note,
                                  style: text.labelSmall?.copyWith(
                                    color: DashboardColors.mutedInk(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DependenciesPanel extends StatelessWidget {
  const _DependenciesPanel({required this.feature});

  final CatalogFeature feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DashboardPanel(
      sectionId: DashboardSectionIds.platformFeatureDependencies,
      icon: DashboardIcons.plans,
      title: 'التبعيات',
      subtitle: 'التبعيات تطرح ولا تضيف: ميزة بلا متطلَّبها لا تعمل.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            feature.requires.isEmpty
                ? 'لا تتطلب أي ميزة أخرى.'
                : 'تتطلب هذه الميزة:',
            style: text.bodySmall,
          ),
          if (feature.requires.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              children: [
                for (final key in feature.requires) StatusChip(label: key),
              ],
            ),
          ],
          if (feature.requiredBy.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.medium),
            _Notice(
              color: scheme.error,
              icon: DashboardIcons.attention,
              // The warning that matters: turning this off collapses these too.
              message:
                  'إيقاف هذه الميزة يُسقِط أيضًا: ${feature.requiredBy.join('، ')}',
            ),
          ],
        ],
      ),
    );
  }
}

class _ImpactPanel extends StatelessWidget {
  const _ImpactPanel({required this.feature});

  final CatalogFeature feature;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final entries = feature.impact.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final offices = entries.fold<int>(0, (sum, e) => sum + e.value);

    return DashboardPanel(
      sectionId: DashboardSectionIds.platformFeatureImpact,
      icon: DashboardIcons.platformOffices,
      title: 'الأثر',
      subtitle: 'من يملك هذه الميزة الآن، وبأي قيمة.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'مُدرجة في',
                  value: '${feature.planCount} باقة',
                  icon: DashboardIcons.plans,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: _MiniStat(
                  label: 'استثناءات مكتبية',
                  value: '${feature.overrideCount}',
                  icon: DashboardIcons.licenses,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (entries.isEmpty)
            Text(
              'لا يوجد مكتب يحلّ هذه الميزة بعد.',
              style: text.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            )
          else
            for (final entry in entries)
              _ImpactBar(
                label: _resolvedValueLabel(entry.key),
                offices: entry.value,
                total: offices,
              ),
        ],
      ),
    );
  }
}

class _ImpactBar extends StatelessWidget {
  const _ImpactBar({
    required this.label,
    required this.offices,
    required this.total,
  });

  final String label;
  final int offices;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final share = total == 0 ? 0.0 : offices / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$offices مكتب',
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              backgroundColor: DashboardColors.well(context),
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.feature});

  final CatalogFeature feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DashboardPanel(
      sectionId: DashboardSectionIds.platformFeatureStatus,
      icon: DashboardIcons.settings,
      title: 'حالة الميزة',
      subtitle: 'أعلى رتبة في سُلَّم الصلاحيات — تعلو على الباقة والاستثناء.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [
              for (final status in const [
                'active',
                'hidden',
                'deprecated',
                'disabled',
              ])
                ChoiceChip(
                  label: Text(_shortStatusLabel(status)),
                  selected: feature.status == status,
                  selectedColor: _statusColor(scheme, status).withAlpha(40),
                  onSelected: feature.status == status
                      ? null
                      : (_) => _apply(context, status),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            _statusDescription(feature.status),
            style: text.bodySmall?.copyWith(
              color: DashboardColors.mutedInk(context),
              height: 1.6,
            ),
          ),
          if (feature.isKillSwitched) ...[
            const SizedBox(height: AppSpacing.small),
            _Notice(
              color: scheme.error,
              icon: DashboardIcons.locked,
              message:
                  'الميزة موقوفة الآن على مستوى المنصة، ولا تعمل لدى أي مكتب '
                  'مهما كانت باقته أو استثناؤه.',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _apply(BuildContext context, String status) async {
    final cubit = context.read<PlatformLicensingCubit>();

    // Rung 0 of the ladder is the most destructive switch in this console, so
    // it is the one action here that asks first.
    if (status == 'disabled') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('إيقاف الميزة على مستوى المنصة'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              'سيتجاوز هذا الإيقاف كل باقة وكل استثناء، وترجع «${feature.nameAr}» '
              'إلى قيمتها الافتراضية '
              '(${FeatureValue.label(feature.defaultValue, unit: feature.unitAr)}) '
              'لدى كل المكاتب فورًا.\n\n'
              'مُدرجة حاليًا في ${feature.planCount} باقة، '
              'ولها ${feature.overrideCount} استثناء مكتبي.'
              '${feature.requiredBy.isEmpty ? '' : '\n\nويسقط معها أيضًا: ${feature.requiredBy.join('، ')}.'}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('إيقاف الميزة'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await cubit.setFeatureStatus(feature.key, status);
  }
}

// ── Small shared pieces ──────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DashboardColors.mutedInk(context)),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.labelSmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
                Text(
                  value,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tinted, bordered sentence — used where the panel has to say something the
/// operator must not skim past.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// The chip-sized status label. The full sentence for `disabled` belongs in the
/// panel's description, not on a chip.
String _shortStatusLabel(String status) =>
    status == 'disabled' ? 'موقوفة' : CatalogFeature.statusLabel(status);

Color _statusColor(ColorScheme scheme, String status) => switch (status) {
  'active' => scheme.secondary,
  'deprecated' => scheme.tertiary,
  'disabled' => scheme.error,
  _ => scheme.outline,
};

String _statusDescription(String status) => switch (status) {
  'active' => 'ظاهرة في الكتالوج وقابلة للإدراج في الباقات.',
  'hidden' => 'مخفية عن بناء الباقات، وتظل سارية لدى كل من يملكها بالفعل.',
  'deprecated' =>
    'مُعلَّمة للإزالة: تعمل لدى من يملكها، ولا يُفترض إدراجها في باقات جديدة.',
  'disabled' =>
    'موقوفة على مستوى المنصة: تتجاوز كل باقة وكل استثناء، وترجع الميزة إلى '
        'قيمتها الافتراضية لدى الجميع.',
  _ => '',
};

/// `impact` arrives with its keys stringified, so `true` reaches the UI as the
/// text "true" rather than as a boolean — labelling it needs the raw form.
String _resolvedValueLabel(String raw) => switch (raw) {
  'true' => 'مفعّلة',
  'false' => 'غير مفعّلة',
  FeatureValue.unlimited => 'بلا حدود',
  _ => raw,
};
