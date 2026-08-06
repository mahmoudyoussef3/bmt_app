import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_kpi_card.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';

/// كتالوج الميزات — what the platform can sell, and where each flag is real.
///
/// Search is the primary interaction, not browsing: at 47 features and growing,
/// nobody scrolls to find one. Each row expands to answer the three questions a
/// catalog has to answer — where is this enforced, what does it depend on, and
/// what would break if I turned it off.
class PlatformFeaturesScreen extends StatelessWidget {
  const PlatformFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        final cubit = context.read<PlatformLicensingCubit>();
        final catalog = state.catalog;
        final visible = state.visibleFeatures;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardModuleHeader(
              icon: DashboardIcons.featureCatalog,
              title: 'كتالوج الميزات',
              subtitle:
                  'كل قدرة تبيعها المنصة، ونوعها، وأين تُطبَّق فعليًا في الكود.',
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  children: [
                    DashboardKpiGrid(
                      children: [
                        DashboardKpiCard(
                          label: 'ميزات الكتالوج',
                          value: '${catalog.features.length}',
                          icon: DashboardIcons.featureCatalog,
                        ),
                        DashboardKpiCard(
                          label: 'مطبَّقة بكود',
                          value: '${catalog.enforcedCount}',
                          icon: DashboardIcons.allClear,
                          detail: 'يوجد مُشغِّل أو حارس أو سياسة',
                        ),
                        DashboardKpiCard(
                          label: 'معلنة فقط',
                          value: '${catalog.declaredCount}',
                          icon: DashboardIcons.attention,
                          detail: 'مُدرجة ولا يوجد كود يطبّقها بعد',
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
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'ابحث بالمفتاح أو الاسم أو التصنيف',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: cubit.searchFeatures,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: visible.isEmpty
                  ? const DashboardEmptyState(
                      icon: DashboardIcons.featureCatalog,
                      title: 'لا توجد ميزة مطابقة',
                    )
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) => _FeatureRow(
                        feature: visible[index],
                        catalog: catalog,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.catalog});

  final CatalogFeature feature;
  final FeatureCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.nameAr,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    feature.key,
                    style: text.labelSmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                catalog.categoryName(feature.categoryKey),
                style: text.bodySmall,
              ),
            ),
            Expanded(
              child: Text(feature.valueTypeLabelAr, style: text.bodySmall),
            ),
            Expanded(
              child: Text(
                FeatureValue.label(feature.defaultValue, unit: feature.unitAr),
                style: text.bodySmall,
              ),
            ),
            EnforcementBadge(isEnforced: feature.isEnforced),
            const SizedBox(width: AppSpacing.small),
            if (feature.isKillSwitched)
              StatusChip(
                label: 'موقوفة',
                color: scheme.error.withAlpha(24),
                textColor: scheme.error,
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (feature.descriptionAr.isNotEmpty) ...[
                  Text(feature.descriptionAr, style: text.bodySmall),
                  const SizedBox(height: AppSpacing.medium),
                ],
                _Section(
                  title: 'أين تُستخدم',
                  child: feature.gates.isEmpty
                      ? Text(
                          // The honest answer, and the reason the badge exists.
                          'لا يوجد كود يطبّق هذه الميزة بعد. يمكن إدراجها في '
                          'باقة، لكنها لن تغيّر أي سلوك.',
                          style: text.bodySmall?.copyWith(
                            color: scheme.tertiary,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final gate in feature.gates)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    StatusChip(label: gate.kindLabelAr),
                                    const SizedBox(width: AppSpacing.small),
                                    Expanded(
                                      child: Text(
                                        '${gate.ref}'
                                        '${gate.note.isEmpty ? '' : ' — ${gate.note}'}',
                                        style: text.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
                _Section(
                  title: 'التبعيات',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.requires.isEmpty
                            ? 'لا تتطلب أي ميزة أخرى.'
                            : 'تتطلب: ${feature.requires.join('، ')}',
                        style: text.bodySmall,
                      ),
                      if (feature.requiredBy.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            // The warning that matters: dependencies only ever
                            // subtract, so turning this off collapses these too.
                            'إيقافها يُسقِط أيضًا: ${feature.requiredBy.join('، ')}',
                            style: text.bodySmall?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: 'الأثر',
                  child: Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: 4,
                    children: [
                      StatusChip(label: 'في ${feature.planCount} باقة'),
                      StatusChip(label: '${feature.overrideCount} استثناء'),
                      for (final entry in feature.impact.entries)
                        StatusChip(
                          label:
                              '${entry.value} مكتب → ${FeatureValue.label(entry.key)}',
                        ),
                      if (feature.isLimit)
                        StatusChip(
                          label: feature.isStock
                              ? 'عدّاد مخزون — الحذف يعيد الحصة'
                              : 'عدّاد تدفّق — الحذف لا يعيد الحصة',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Row(
                  children: [
                    Text('حالة الميزة', style: text.bodySmall),
                    const SizedBox(width: AppSpacing.medium),
                    DropdownButton<String>(
                      value: feature.status,
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('نشطة')),
                        DropdownMenuItem(value: 'hidden', child: Text('مخفية')),
                        DropdownMenuItem(
                          value: 'deprecated',
                          child: Text('مهجورة'),
                        ),
                        DropdownMenuItem(
                          value: 'disabled',
                          child: Text('إيقاف على مستوى المنصة'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          cubit.setFeatureStatus(feature.key, value);
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Text(
                        // Rung 0 of the ladder, said where the switch is.
                        'الإيقاف على مستوى المنصة يتجاوز كل باقة وكل استثناء: '
                        'ترجع الميزة إلى قيمتها الافتراضية لدى الجميع.',
                        style: text.labelSmall?.copyWith(
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          child,
        ],
      ),
    );
  }
}
