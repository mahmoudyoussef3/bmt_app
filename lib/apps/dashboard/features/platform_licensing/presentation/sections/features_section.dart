import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/master_detail_layout.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import '../widgets/licensing_layout.dart';
import '../widgets/licensing_widgets.dart';

/// الميزات — what the platform can sell, and where each flag is real.
///
/// **List → detail.** The catalog has to answer six things about a feature — its
/// type, its default, where it is enforced, what it depends on, who has it, and
/// whether it is switched on — and no list carries six columns legibly. The list
/// carries what you scan by; the detail answers the rest, labelled.
///
/// Master/detail is deliberate here and *not* used by the two editing surfaces
/// (plans, licences), which open full width. The rule the console follows: you
/// browse a reference in a split pane because you skim many rows and read one;
/// you edit in a workspace because editing needs the room.
///
/// **One line of chrome, not three hundred pixels of it.** The screen used to
/// open with four KPI tiles inside a folding header, then a folding filter
/// panel holding three unlabelled rows of chips — all above the first row of
/// data. The counts are now a stat line, and the three narrowing axes are one
/// toolbar: a search field, a segmented enforcement switch, and two named
/// dropdowns. Nothing about the filter state is hidden, and nothing about it
/// costs a fold.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key, required this.state, this.tabBar});

  final PlatformLicensingLoaded state;
  final Widget? tabBar;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedFeature;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CatalogHeader(state: state, tabBar: tabBar),
        const SizedBox(height: AppSpacing.medium),
        _CatalogToolbar(state: state),
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
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.state, required this.tabBar});

  final PlatformLicensingLoaded state;
  final Widget? tabBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catalog = state.catalog;

    return LicensingConsoleHeader(
      icon: DashboardIcons.featureCatalog,
      title: 'الباقات والميزات',
      subtitle: 'كل قدرة تبيعها المنصة، ونوعها، وأين تُطبَّق فعليًا في الكود.',
      tabBar: tabBar,
      stats: [
        LicensingStat(
          icon: DashboardIcons.featureCatalog,
          value: '${catalog.features.length}',
          label: 'ميزة في الكتالوج',
        ),
        LicensingStat(
          icon: DashboardIcons.allClear,
          value: '${catalog.enforcedCount}',
          label: 'مطبَّقة بكود',
          color: scheme.secondary,
        ),
        LicensingStat(
          icon: DashboardIcons.attention,
          value: '${catalog.declaredCount}',
          label: 'معلنة ولا كود يطبّقها',
          color: catalog.declaredCount > 0 ? scheme.tertiary : null,
        ),
        LicensingStat(
          icon: DashboardIcons.settings,
          value: switch (state.settings.enforcementMode) {
            'off' => 'معطّل',
            'shadow' => 'وضع الظل',
            _ => 'مفعّل',
          },
          label: 'وضع التطبيق',
        ),
      ],
    );
  }
}

/// Search, enforcement, category and status — on one line, each named.
class _CatalogToolbar extends StatefulWidget {
  const _CatalogToolbar({required this.state});

  final PlatformLicensingLoaded state;

  @override
  State<_CatalogToolbar> createState() => _CatalogToolbarState();
}

class _CatalogToolbarState extends State<_CatalogToolbar> {
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

    return LicensingToolbar(
      search: DebouncedSearchField(
        key: ValueKey('feature-search-$_searchEpoch'),
        initialValue: state.featureSearch,
        hintText: 'ابحث بالاسم أو المفتاح أو الوصف',
        onChanged: cubit.searchFeatures,
      ),
      filters: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
          segments: [
            const ButtonSegment(value: 'all', label: Text('الكل')),
            ButtonSegment(
              value: 'enforced',
              label: Text('مطبَّقة بكود (${catalog.enforcedCount})'),
            ),
            ButtonSegment(
              value: 'declared',
              label: Text('معلنة فقط (${catalog.declaredCount})'),
            ),
          ],
          selected: {state.featureEnforcementFilter ?? 'all'},
          onSelectionChanged: (selection) => cubit.filterFeaturesByEnforcement(
            selection.first == 'all' ? null : selection.first,
          ),
        ),
        _FilterDropdown(
          label: 'التصنيف',
          value: state.featureCategoryFilter == null
              ? 'الكل'
              : catalog.categoryName(state.featureCategoryFilter!),
          options: [
            (value: null, label: 'الكل'),
            for (final category in catalog.categories)
              if ((categoryCounts[category.key] ?? 0) > 0)
                (
                  value: category.key,
                  label: '${category.nameAr} (${categoryCounts[category.key]})',
                ),
          ],
          onSelected: cubit.filterFeaturesByCategory,
        ),
        _FilterDropdown(
          label: 'الحالة',
          value: state.featureStatusFilter == null
              ? 'الكل'
              : _shortStatusLabel(state.featureStatusFilter!),
          options: [
            (value: null, label: 'الكل'),
            for (final status in const [
              'active',
              'hidden',
              'deprecated',
              'disabled',
            ])
              if ((statusCounts[status] ?? 0) > 0)
                (
                  value: status,
                  label:
                      '${_shortStatusLabel(status)} (${statusCounts[status]})',
                ),
          ],
          onSelected: cubit.filterFeaturesByStatus,
        ),
        if (state.hasFeatureFilters)
          TextButton.icon(
            onPressed: () {
              setState(() => _searchEpoch++);
              cubit.clearFeatureFilters();
            },
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('مسح التصفية'),
          ),
      ],
    );
  }
}

/// A named dropdown: the label is always visible, so the control never asks the
/// operator to infer its axis from whichever value happens to be selected.
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String value;
  final List<({String? value, String label})> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    return PopupMenuButton<String>(
      tooltip: label,

      onSelected: (picked) => onSelected(picked == '' ? null : picked),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(value: option.value ?? '', child: Text(option.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: radius,
          border: Border.all(color: DashboardColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: theme.textTheme.labelMedium?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: DashboardColors.mutedInk(context),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final group in groups)
                          _CategoryBlock(
                            group: group,
                            selectedKey: state.selectedFeatureKey,
                            onSelect: cubit.selectFeature,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A category heading and its rows.
///
/// Flat, not collapsible: the list is already narrowed by a toolbar the
/// operator can see, and a column of folded headings meant the rows a search
/// had just found could still be hidden behind a remembered collapse.
class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.group,
    required this.selectedKey,
    required this.onSelect,
  });

  final FeatureGroup group;
  final String? selectedKey;
  final ValueChanged<String> onSelect;

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
              Expanded(
                child: Text(
                  group.nameAr,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${group.features.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ],
          ),
        ),
        for (final feature in group.features)
          _FeatureRow(
            feature: feature,
            selected: feature.key == selectedKey,
            onTap: () => onSelect(feature.key),
          ),
      ],
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
    final reach = [
      if (feature.planCount > 0) 'في ${feature.planCount} باقة',
      if (feature.overrideCount > 0) '${feature.overrideCount} استثناء',
    ].join(' · ');

    return Material(
      color: selected ? scheme.primary.withAlpha(16) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
          decoration: BoxDecoration(
            border: BorderDirectional(
              top: BorderSide(color: DashboardColors.divider(context)),

              start: BorderSide(
                color: selected ? scheme.primary : Colors.transparent,
                width: 3,
              ),
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

                        if (feature.isKillSwitched)
                          _RowMark(label: 'موقوفة', color: scheme.error)
                        else if (!feature.isEnforced)
                          _RowMark(label: 'معلنة فقط', color: scheme.tertiary),
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
                        style: text.labelSmall?.copyWith(color: scheme.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
          width: 12,
          height: 12,
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

/// Three panels, not six.
///
/// The old pane split one feature across التعريف / أين تُطبَّق / التبعيات /
/// الأثر / حالة الميزة, each a folding card — five headers and five chevrons
/// for a page of facts. They are now three: what it is, where it bites, and
/// what it is doing to the platform right now.
class _FeatureDetail extends StatelessWidget {
  const _FeatureDetail({required this.feature, required this.state});

  final CatalogFeature feature;
  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: PageStorageKey('feature-detail-${feature.key}'),
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.medium),
      children: [
        _DetailHeader(feature: feature, state: state),
        const SizedBox(height: AppSpacing.medium),
        _DefinitionPanel(feature: feature),
        const SizedBox(height: AppSpacing.medium),
        _EnforcementPanel(feature: feature),
        const SizedBox(height: AppSpacing.medium),
        _ReachPanel(feature: feature),
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
      icon: DashboardIcons.settings,
      title: 'التعريف',
      subtitle: 'ما الذي تضبطه هذه الميزة، وبأي قيمة تبدأ.',
      child: LicensingFieldGrid(
        fields: [
          (label: 'المفتاح', value: feature.key),
          (label: 'النوع', value: feature.valueTypeLabelAr),
          (
            label: 'القيمة الافتراضية',
            value: FeatureValue.label(
              feature.defaultValue,
              unit: feature.unitAr,
            ),
          ),
          if (feature.allowedValues.isNotEmpty)
            (label: 'القيم المسموحة', value: feature.allowedValues.join('، ')),
          if (feature.isLimit)
            (
              label: 'نوع العدّاد',

              value: feature.isStock
                  ? 'مخزون — الحذف يعيد الحصة'
                  : 'تدفّق — الحذف لا يعيد الحصة',
            ),
          if (feature.meterPeriod != null && feature.meterPeriod!.isNotEmpty)
            (label: 'دورة العدّاد', value: feature.meterPeriod!),
          (
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

/// Where the code bites, and what has to be on for it to bite at all.
///
/// Gates and dependencies were two panels answering halves of one question:
/// "if I sell this, does anything happen?" A gate with an unmet requirement
/// still does nothing, so the two belong on the same card.
class _EnforcementPanel extends StatelessWidget {
  const _EnforcementPanel({required this.feature});

  final CatalogFeature feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DashboardPanel(
      icon: DashboardIcons.licenses,
      title: 'أين تُطبَّق وما تتطلبه',
      subtitle: 'المواضع التي يفرض فيها الكود هذه الميزة، وشروط عملها.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (feature.gates.isEmpty)
            LicensingNotice(
              color: scheme.tertiary,
              icon: DashboardIcons.attention,

              message:
                  'لا يوجد كود يطبّق هذه الميزة بعد. يمكن إدراجها في باقة، '
                  'لكنها لن تغيّر أي سلوك لدى المكاتب.',
            )
          else
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
          const SizedBox(height: AppSpacing.small),
          Divider(height: 1, color: DashboardColors.divider(context)),
          const SizedBox(height: AppSpacing.small),
          Text(
            feature.requires.isEmpty
                ? 'لا تتطلب أي ميزة أخرى.'
                : 'تتطلب هذه الميزة — والتبعيات تطرح ولا تضيف، فميزة بلا '
                      'متطلَّبها لا تعمل:',
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
            const SizedBox(height: AppSpacing.small),
            LicensingNotice(
              color: scheme.error,
              icon: DashboardIcons.attention,

              message:
                  'إيقاف هذه الميزة يُسقِط أيضًا: ${feature.requiredBy.join('، ')}',
            ),
          ],
        ],
      ),
    );
  }
}

/// Who has it now, and the switch that takes it away from all of them.
class _ReachPanel extends StatelessWidget {
  const _ReachPanel({required this.feature});

  final CatalogFeature feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final entries = feature.impact.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final offices = entries.fold<int>(0, (sum, e) => sum + e.value);

    return DashboardPanel(
      icon: DashboardIcons.platformOffices,
      title: 'الأثر والحالة',
      subtitle: 'من يملك هذه الميزة الآن — وحالتها تعلو على الباقة والاستثناء.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LicensingStatStrip(
            stats: [
              LicensingStat(
                icon: DashboardIcons.plans,
                value: '${feature.planCount}',
                label: 'باقة تُدرجها',
              ),
              LicensingStat(
                icon: DashboardIcons.locked,
                value: '${feature.overrideCount}',
                label: 'استثناء مكتبي',
              ),
              LicensingStat(
                icon: DashboardIcons.platformOffices,
                value: '$offices',
                label: 'مكتب يحلّها',
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
          const SizedBox(height: AppSpacing.small),
          Divider(height: 1, color: DashboardColors.divider(context)),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'حالة الميزة',
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.small),
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
            LicensingNotice(
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
