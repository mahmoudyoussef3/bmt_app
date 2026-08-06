import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/master_detail_layout.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';

/// الخطط والباقات — the plan builder.
///
/// Master/detail: the plan list on one side, and on the other the catalog
/// grouped by category with a control per row typed by `value_type`.
///
/// The sentence this screen has to keep saying is that a save takes effect
/// **immediately for every subscribed office** — the resolver reads plan values
/// at resolution time and there is no per-office copy to sync — and that the
/// state it replaced is kept as a revision.
class PlatformPlansScreen extends StatelessWidget {
  const PlatformPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardModuleHeader(
            icon: DashboardIcons.plans,
            title: 'الخطط والباقات',
            subtitle:
                'ما تبيعه المنصة للمكاتب. الباقة قالب بلا سلوك: كل ما "تفعله" '
                'قيمة يقرأها المُحلِّل، ولهذا يمكن تعديلها وهي حيّة.',
          ),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: MasterDetailLayout(
              masterFlex: 2,
              detailFlex: 4,
              placeholderTitle: 'اختر باقة لعرض ميزاتها',
              placeholderSubtitle:
                  'التعديل يسري فورًا على كل مكتب مشترك في الباقة.',
              master: _PlanList(state: state),
              detail: state.selectedPlan == null
                  ? null
                  : _PlanDetailPanel(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final scheme = Theme.of(context).colorScheme;

    return DashboardPanel(
      icon: DashboardIcons.plans,
      title: 'الباقات',
      subtitle: '${state.plans.length} باقة',
      child: state.plans.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.plans,
              title: 'لا توجد باقات',
              message: 'أنشئ باقة لتبدأ ترخيص المكاتب.',
            )
          : Column(
              children: [
                for (final plan in state.plans)
                  _PlanTile(
                    plan: plan,
                    selected: state.selectedPlan?.plan.id == plan.id,
                    onTap: () => cubit.selectPlan(plan.id),
                    accent: scheme.primary,
                  ),
              ],
            ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  final LicensingPlan plan;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.small),
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: selected
              ? accent.withAlpha(16)
              : DashboardColors.well(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent.withAlpha(90)
                : DashboardColors.border(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.nameAr,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusChip(label: plan.statusLabelAr),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.taglineAr.isEmpty ? plan.key : plan.taglineAr,
              style: text.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: 4,
              children: [
                _Meta(
                  icon: DashboardIcons.platformOffices,
                  label: '${plan.officeCount} مكتب',
                ),
                _Meta(
                  icon: DashboardIcons.payments,
                  label: plan.priceMonthly == null
                      ? 'سعر تفاوضي'
                      : '${licensingMoney(plan.priceMonthly, plan.currency)} / شهر',
                ),
                if (plan.trialDays > 0)
                  _Meta(
                    icon: DashboardIcons.time,
                    label: 'تجربة ${plan.trialDays} يوم',
                  ),
                if (!plan.isPublic)
                  const _Meta(
                    icon: DashboardIcons.locked,
                    label: 'بالتعيين فقط',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DashboardColors.mutedInk(context)),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
    );
  }
}

class _PlanDetailPanel extends StatefulWidget {
  const _PlanDetailPanel({required this.state});

  final PlatformLicensingLoaded state;

  @override
  State<_PlanDetailPanel> createState() => _PlanDetailPanelState();
}

class _PlanDetailPanelState extends State<_PlanDetailPanel> {
  /// The working copy. A key that is ABSENT means "fall through to the catalog
  /// default" — a different statement from setting it false — and the server
  /// replaces the map wholesale, so this must always be the complete picture.
  late Map<String, Object?> _draft = {...widget.state.selectedPlan!.values};
  late String _planId = widget.state.selectedPlan!.plan.id;

  @override
  void didUpdateWidget(covariant _PlanDetailPanel old) {
    super.didUpdateWidget(old);
    final detail = widget.state.selectedPlan;
    // Only reset the draft when the operator moved to a different plan, so a
    // background refresh cannot silently discard unsaved edits.
    if (detail != null && detail.plan.id != _planId) {
      _planId = detail.plan.id;
      _draft = {...detail.values};
    }
  }

  bool get _isDirty {
    final saved = widget.state.selectedPlan!.values;
    if (saved.length != _draft.length) return true;
    for (final entry in _draft.entries) {
      if ('${saved[entry.key]}' != '${entry.value}') return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.state.selectedPlan!;
    final cubit = context.read<PlatformLicensingCubit>();
    final catalog = widget.state.catalog;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detail.plan.nameAr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => cubit.previewPlan(detail.plan.id),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('معاينة'),
                    ),
                    TextButton.icon(
                      onPressed: () => _clone(context, cubit, detail),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('نسخ'),
                    ),
                    if (!detail.plan.isArchived)
                      TextButton.icon(
                        onPressed: () => cubit.savePlanDetails({
                          'id': detail.plan.id,
                          'status': 'archived',
                          'reason': 'أرشفة من وحدة التحكم',
                        }),
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: const Text('أرشفة'),
                      ),
                    const SizedBox(width: AppSpacing.small),
                    FilledButton.icon(
                      onPressed: _isDirty ? () => _save(context, cubit) : null,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('حفظ'),
                    ),
                  ],
                ),
                if (detail.plan.isArchived)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                    child: Text(
                      // Archiving is not deletion: the offices already on it keep
                      // resolving exactly as before.
                      'باقة مؤرشفة — المكاتب المشتركة تعمل كما هي، ولا يمكن '
                      'تعيينها لمكتب جديد.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'الميزات'),
                    Tab(text: 'المكاتب'),
                    Tab(text: 'السجل'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: TabBarView(
              children: [
                _FeatureValuesTab(
                  catalog: catalog,
                  draft: _draft,
                  preview: widget.state.planPreview,
                  onChanged: (key, value) =>
                      setState(() => _draft[key] = value),
                  onCleared: (key) => setState(() => _draft.remove(key)),
                ),
                _PlanOfficesTab(detail: detail),
                _PlanRevisionsTab(detail: detail, catalog: catalog),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, PlatformLicensingCubit cubit) async {
    final reason = await promptForReason(
      context,
      title: 'حفظ تعديلات الباقة',
      description:
          'سيسري التعديل فورًا على كل مكتب مشترك في هذه الباقة، وستُحفظ الحالة '
          'السابقة كنسخة في السجل يمكن الرجوع إليها.',
      confirmLabel: 'حفظ',
    );
    if (reason == null || !context.mounted) return;
    await cubit.savePlanValues(_planId, _draft, reason);
  }

  Future<void> _clone(
    BuildContext context,
    PlatformLicensingCubit cubit,
    PlanDetail detail,
  ) async {
    final key = await promptForReason(
      context,
      title: 'نسخ الباقة',
      description:
          'المفتاح الجديد بحروف إنجليزية صغيرة وأرقام وشرطات فقط. تُنشأ النسخة '
          'كمسودة غير معروضة.',
      confirmLabel: 'إنشاء',
      minLength: 3,
    );
    if (key == null || !context.mounted) return;
    await cubit.clonePlan(detail.plan.id, key, 'نسخة من ${detail.plan.nameAr}');
  }
}

class _FeatureValuesTab extends StatelessWidget {
  const _FeatureValuesTab({
    required this.catalog,
    required this.draft,
    required this.onChanged,
    required this.onCleared,
    this.preview,
  });

  final FeatureCatalog catalog;
  final Map<String, Object?> draft;
  final Map<String, dynamic>? preview;
  final void Function(String key, Object? value) onChanged;
  final ValueChanged<String> onCleared;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      children: [
        if (preview != null) ...[
          DashboardPanel(
            icon: Icons.visibility_outlined,
            title: 'معاينة الصلاحيات الفعلية',
            subtitle:
                'ناتج المُحلِّل نفسه على مكتب افتراضي بهذه الباقة وبلا استثناءات.',
            child: Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              children: [
                for (final entry in preview!.entries.take(60))
                  StatusChip(
                    label:
                        '${(entry.value as Map)['name_ar'] ?? entry.key}: '
                        '${FeatureValue.label((entry.value as Map)['value'])}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        for (final category in catalog.categories)
          _CategorySection(
            category: category,
            features:
                catalog.features
                    .where(
                      (f) =>
                          f.categoryKey == category.key && f.status != 'hidden',
                    )
                    .toList()
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
            draft: draft,
            onChanged: onChanged,
            onCleared: onCleared,
          ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          // The distinction that trips everybody up, said once, in place.
          'ميزة بلا قيمة في الباقة ترجع إلى الافتراضي المسجَّل في الكتالوج — '
          'وهذا ليس نفس معنى «مُعطَّلة».',
          style: text.bodySmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.features,
    required this.draft,
    required this.onChanged,
    required this.onCleared,
  });

  final FeatureCategory category;
  final List<CatalogFeature> features;
  final Map<String, Object?> draft;
  final void Function(String key, Object? value) onChanged;
  final ValueChanged<String> onCleared;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: DashboardPanel(
        icon: DashboardIcons.featureCatalog,
        title: category.nameAr,
        child: Column(
          children: [
            for (final feature in features)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xSmall,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  feature.nameAr,
                                  style: text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              if (!feature.isEnforced)
                                const EnforcementBadge(isEnforced: false),
                              if (feature.isKillSwitched) ...[
                                const SizedBox(width: AppSpacing.xSmall),
                                StatusChip(
                                  label: 'موقوفة على مستوى المنصة',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withAlpha(24),
                                  textColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            draft.containsKey(feature.key)
                                ? feature.key
                                : '${feature.key} — يتبع الافتراضي '
                                      '(${FeatureValue.label(feature.defaultValue)})',
                            style: text.labelSmall?.copyWith(
                              color: DashboardColors.mutedInk(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FeatureValueField(
                      feature: feature,
                      value: draft[feature.key],
                      onChanged: (v) => onChanged(feature.key, v),
                    ),
                    IconButton(
                      tooltip: 'إرجاع إلى الافتراضي',
                      icon: const Icon(
                        Icons.settings_backup_restore_rounded,
                        size: 18,
                      ),
                      onPressed: draft.containsKey(feature.key)
                          ? () => onCleared(feature.key)
                          : null,
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

class _PlanOfficesTab extends StatelessWidget {
  const _PlanOfficesTab({required this.detail});

  final PlanDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.offices.isEmpty) {
      return const DashboardEmptyState(
        icon: DashboardIcons.platformOffices,
        title: 'لا يوجد مكتب على هذه الباقة',
      );
    }
    return ListView(
      children: [
        for (final office in detail.offices)
          ListTile(
            leading: const Icon(DashboardIcons.platformOffices),
            title: Text(office.name),
            trailing: LicenseStatusChip(
              status: office.status,
              label: office.status,
            ),
          ),
      ],
    );
  }
}

class _PlanRevisionsTab extends StatelessWidget {
  const _PlanRevisionsTab({required this.detail, required this.catalog});

  final PlanDetail detail;
  final FeatureCatalog catalog;

  @override
  Widget build(BuildContext context) {
    if (detail.revisions.isEmpty) {
      return const DashboardEmptyState(
        icon: DashboardIcons.audit,
        title: 'لا توجد نسخ سابقة',
        message: 'تُحفظ نسخة تلقائيًا قبل كل تعديل.',
      );
    }

    final text = Theme.of(context).textTheme;
    return ListView(
      children: [
        for (final revision in detail.revisions)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.small),
            child: ExpansionTile(
              title: Text('نسخة ${revision.revision}'),
              subtitle: Text(
                '${licensingDate(revision.createdAt)}'
                '${revision.reason.isEmpty ? '' : ' — ${revision.reason}'}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in _changes(revision.features).entries)
                        Text(
                          '${entry.key}: ${entry.value}',
                          style: text.bodySmall,
                        ),
                      if (_changes(revision.features).isEmpty)
                        Text(
                          'لا فروق عن الحالة الحالية.',
                          style: text.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// A side-by-side diff against what the plan holds now, rather than a raw
  /// snapshot dump: "what changed" is the only question a revision answers.
  Map<String, String> _changes(Map<String, dynamic> snapshot) {
    final keys = {...snapshot.keys, ...detail.values.keys};
    final out = <String, String>{};
    for (final key in keys) {
      final before = snapshot[key];
      final after = detail.values[key];
      if ('$before' == '$after') continue;
      final name = catalog.features
          .firstWhere(
            (f) => f.key == key,
            orElse: () => CatalogFeature(
              key: key,
              nameAr: key,
              nameEn: key,
              categoryKey: '',
              valueType: 'boolean',
              defaultValue: null,
              status: 'active',
              isEnforced: false,
            ),
          )
          .nameAr;
      out[name] =
          '${FeatureValue.label(before)} ← ${FeatureValue.label(after)}';
    }
    return out;
  }
}
