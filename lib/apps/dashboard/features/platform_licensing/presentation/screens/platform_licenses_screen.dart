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
import '../../domain/entities/office_license.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';

/// التراخيص — every office's licence, and the one screen that answers
/// "why does this office have this?".
///
/// The answer lives in the `source` column of the resolved feature table: which
/// rung of the ladder produced each value. That single field is the difference
/// between a two-minute support conversation and a twenty-minute one.
class PlatformLicensesScreen extends StatelessWidget {
  const PlatformLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LicensesHeader(state: state),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: MasterDetailLayout(
              masterFlex: 2,
              detailFlex: 3,
              placeholderTitle: 'اختر مكتبًا لعرض ترخيصه',
              placeholderSubtitle:
                  'كل قيمة تظهر ومعها مصدرها: باقة، استثناء، أو حالة ترخيص.',
              master: _LicenseList(state: state),
              detail: state.selectedOffice == null
                  ? null
                  : _OfficeLicensePanel(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicensesHeader extends StatelessWidget {
  const _LicensesHeader({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final health = state.health;
    final text = Theme.of(context).textTheme;

    return DashboardModuleHeader(
      icon: DashboardIcons.licenses,
      title: 'التراخيص',
      subtitle: 'الحالة التجارية لكل مكتب، وما تسمح به فعليًا.',
      actions: [
        TextButton.icon(
          onPressed: cubit.runLifecycle,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('تشغيل دورة الحياة'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EnforcementModeBar(state: state),
            const SizedBox(height: AppSpacing.medium),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 1100 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.small,
                  crossAxisSpacing: AppSpacing.small,
                  childAspectRatio: 2.6,
                  children: [
                    HealthList(
                      icon: DashboardIcons.time,
                      title: 'تجارب تنتهي قريبًا',
                      rows: health.trialsEnding,
                      onTapOffice: cubit.selectOffice,
                      describe: (r) =>
                          '${r['office_name']} — ${licensingDate(DateTime.tryParse('${r['trial_ends_at']}'))}',
                    ),
                    HealthList(
                      icon: DashboardIcons.attention,
                      title: 'متأخرة أو موقوفة',
                      rows: health.pastDue,
                      onTapOffice: cubit.selectOffice,
                      describe: (r) => '${r['office_name']} — ${r['status']}',
                    ),
                    HealthList(
                      icon: DashboardIcons.usage,
                      title: 'تجاوزت حدًّا',
                      rows: health.overLimit,
                      onTapOffice: cubit.selectOffice,
                      describe: (r) =>
                          '${r['office_name']} — ${r['name_ar']}: ${r['used']} / ${r['limit']}',
                    ),
                    HealthList(
                      icon: DashboardIcons.featureCatalog,
                      title: 'مُباعة بلا كود',
                      rows: health.soldButDeclared,
                      describe: (r) => '${r['plan_key']} — ${r['name_ar']}',
                      emptyLabel: 'لا توجد باقة تَعِد بما لا يفعله الكود.',
                    ),
                    HealthList(
                      icon: DashboardIcons.locked,
                      title: 'استثناءات تنتهي قريبًا',
                      rows: health.overridesExpiring,
                      onTapOffice: cubit.selectOffice,
                      describe: (r) =>
                          '${r['office_name']} — ${r['feature_key']}',
                    ),
                    HealthList(
                      icon: DashboardIcons.platformOffices,
                      title: 'مكاتب بلا ترخيص',
                      rows: health.officesWithoutLicense,
                      onTapOffice: cubit.selectOffice,
                      describe: (r) => '${r['office_name']}',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              // The line that stops a shadow-mode log being read as an accusation.
              'تجاوز الحد حالة حقيقية وليست خطأ: الحدود تمنع الإنشاء الجديد ولا '
              'تمسّ ما هو قائم، فالمكتب الذي خُفِّضت باقته يحتفظ بكل صفوفه.',
              style: text.labelSmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnforcementModeBar extends StatelessWidget {
  const _EnforcementModeBar({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final scheme = Theme.of(context).colorScheme;
    final mode = state.settings.enforcementMode;
    final color = switch (mode) {
      'enforcing' => scheme.secondary,
      'shadow' => scheme.tertiary,
      _ => scheme.outline,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(DashboardIcons.settings, color: color, size: 20),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وضع التطبيق: ${state.settings.modeLabelAr}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  // The kill switch, described where it lives.
                  'الإرجاع إلى «معطّل» يعيد سلوك المنصة كما كان فورًا وبلا نشر '
                  'إصدار جديد.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
              ],
            ),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'off', label: Text('معطّل')),
              ButtonSegment(value: 'shadow', label: Text('ظل')),
              ButtonSegment(value: 'enforcing', label: Text('مفعّل')),
            ],
            selected: {mode},
            onSelectionChanged: (selection) =>
                cubit.setEnforcementMode(selection.first),
          ),
        ],
      ),
    );
  }
}

class _LicenseList extends StatelessWidget {
  const _LicenseList({required this.state});

  final PlatformLicensingLoaded state;

  static const _statuses = <String?, String>{
    null: 'الكل',
    'active': 'نشطة',
    'trialing': 'تجريبية',
    'past_due': 'متأخرة',
    'grace': 'مهلة',
    'suspended': 'موقوفة',
    'expired': 'منتهية',
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final rows = state.visibleLicenses;
    final scheme = Theme.of(context).colorScheme;

    return DashboardPanel(
      icon: DashboardIcons.licenses,
      title: 'المكاتب',
      subtitle:
          '${state.licenses.length} مكتب · ${state.overLimitOffices} تجاوز · '
          '${state.delistedOffices} محجوب عن السوق',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in _statuses.entries)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xSmall),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: state.licenseStatusFilter == entry.key,
                      onSelected: (_) => cubit.filterLicenses(entry.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          if (rows.isEmpty)
            const DashboardEmptyState(
              icon: DashboardIcons.licenses,
              title: 'لا يوجد مكتب بهذه الحالة',
            )
          else
            for (final row in rows)
              _LicenseTile(
                row: row,
                selected: state.selectedOffice?.officeId == row.officeId,
                accent: scheme.primary,
                onTap: () => cubit.selectOffice(row.officeId),
              ),
        ],
      ),
    );
  }
}

class _LicenseTile extends StatelessWidget {
  const _LicenseTile({
    required this.row,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final OfficeLicenseRow row;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.officeName,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    row.planNameAr.isEmpty ? 'بلا باقة' : row.planNameAr,
                    style: text.bodySmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                ],
              ),
            ),
            if (row.overLimitCount > 0) ...[
              StatusChip(
                label: 'تجاوز ${row.overLimitCount}',
                color: scheme.error.withAlpha(24),
                textColor: scheme.error,
              ),
              const SizedBox(width: AppSpacing.xSmall),
            ],
            if (row.isDelisted) ...[
              Tooltip(
                message: 'محجوب عن سوق العملاء',
                child: Icon(
                  DashboardIcons.locked,
                  size: 16,
                  color: scheme.error,
                ),
              ),
              const SizedBox(width: AppSpacing.xSmall),
            ],
            LicenseStatusChip(status: row.status, label: row.statusLabelAr),
          ],
        ),
      ),
    );
  }
}

class _OfficeLicensePanel extends StatelessWidget {
  const _OfficeLicensePanel({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final detail = state.selectedOffice!;
    final license = detail.license;
    final cubit = context.read<PlatformLicensingCubit>();

    return ListView(
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.officeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${license.planNameAr} · ${license.statusLabelAr}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'إغلاق',
                icon: const Icon(Icons.close_rounded),
                onPressed: cubit.clearOfficeSelection,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _LicenseSection(state: state, detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _LimitsSection(detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _EffectiveFeaturesSection(detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _OverridesSection(state: state, detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _InvoicesSection(detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _ActivitySection(detail: detail),
      ],
    );
  }
}

class _LicenseSection extends StatelessWidget {
  const _LicenseSection({required this.state, required this.detail});

  final PlatformLicensingLoaded state;
  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final license = detail.license;

    return DashboardPanel(
      icon: DashboardIcons.licenses,
      title: 'الترخيص',
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz_rounded),
        onSelected: (action) => _run(context, cubit, action),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'assign', child: Text('تعيين باقة')),
          if (license.status == 'trialing')
            const PopupMenuItem(value: 'extend', child: Text('تمديد التجربة')),
          if (license.isHeld)
            const PopupMenuItem(value: 'restore', child: Text('استئناف'))
          else
            const PopupMenuItem(value: 'suspend', child: Text('إيقاف مؤقت')),
          const PopupMenuItem(value: 'invoice', child: Text('إصدار فاتورة')),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LicensingField(label: 'الباقة', value: license.planNameAr),
          LicensingField(label: 'الحالة', value: license.statusLabelAr),
          LicensingField(
            label: 'الدورة',
            value: switch (license.billingCycle) {
              'monthly' => 'شهرية',
              'yearly' => 'سنوية',
              'custom' => 'عقد مخصص',
              'free' => 'مجانية',
              _ => '—',
            },
          ),
          LicensingField(
            label: 'السعر',
            value: licensingMoney(license.price, license.currency),
          ),
          if (license.trialEndsAt != null)
            LicensingField(
              label: 'تنتهي التجربة',
              value: licensingDate(license.trialEndsAt),
            ),
          LicensingField(
            label: 'نهاية المدة',
            value: licensingDate(license.periodEnd),
          ),
          LicensingField(
            label: 'تجديد تلقائي',
            value: license.autoRenew ? 'نعم' : 'لا',
          ),
          LicensingField(
            label: 'حجب السوق',
            value: switch (detail.licensingHold) {
              'delisted' => 'محجوب عن العملاء',
              'read_only' => 'قراءة فقط',
              _ => 'لا يوجد',
            },
          ),
          if (license.suspendedReason != null)
            LicensingField(
              label: 'سبب الإيقاف',
              value: license.suspendedReason!,
            ),
        ],
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    PlatformLicensingCubit cubit,
    String action,
  ) async {
    switch (action) {
      case 'assign':
        final planId = await _pickPlan(context);
        if (planId == null || !context.mounted) return;
        await cubit.assignPlan(detail.officeId, planId);

      case 'suspend':
        final reason = await promptForReason(
          context,
          title: 'إيقاف الترخيص مؤقتًا',
          // Said at the moment of the decision, because this is the action most
          // often assumed to be a blackout.
          description:
              'المكتب سيتحوّل إلى وضع القراءة فقط: لا إنشاء رحلات أو سائقين أو '
              'خطوط، ويختفي من سوق العملاء. التذاكر المُباعة والرحلات الجارية '
              'ودخول الكباتن تكمل كالمعتاد.',
          confirmLabel: 'إيقاف',
        );
        if (reason == null || !context.mounted) return;
        await cubit.setLicenseStatus(detail.officeId, 'suspended', reason);

      case 'restore':
        final reason = await promptForReason(
          context,
          title: 'استئناف الترخيص',
          confirmLabel: 'استئناف',
        );
        if (reason == null || !context.mounted) return;
        await cubit.setLicenseStatus(detail.officeId, 'active', reason);

      case 'extend':
        final reason = await promptForReason(
          context,
          title: 'تمديد الفترة التجريبية ١٤ يومًا',
          confirmLabel: 'تمديد',
        );
        if (reason == null || !context.mounted) return;
        await cubit.extendTrial(detail.officeId, 14, reason);

      case 'invoice':
        await cubit.issueInvoice(detail.officeId);
    }
  }

  Future<String?> _pickPlan(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('تعيين باقة'),
        children: [
          for (final plan in state.plans.where((p) => !p.isArchived))
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(plan.id),
              child: ListTile(
                title: Text(plan.nameAr),
                subtitle: Text(
                  plan.priceMonthly == null
                      ? 'سعر تفاوضي'
                      : '${licensingMoney(plan.priceMonthly, plan.currency)} / شهر',
                ),
                trailing: StatusChip(label: plan.statusLabelAr),
              ),
            ),
        ],
      ),
    );
  }
}

class _LimitsSection extends StatelessWidget {
  const _LimitsSection({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final limits = detail.entitlements.limits;
    return DashboardPanel(
      icon: DashboardIcons.usage,
      title: 'الحدود والاستخدام',
      subtitle: detail.overLimits.isEmpty
          ? null
          : 'تجاوز ${detail.overLimits.length} حدًّا',
      child: limits.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.usage,
              title: 'لا توجد حدود على هذه الباقة',
            )
          : Column(
              children: [
                for (final limit in limits)
                  UsageBar(
                    label: limit.nameAr,
                    used: limit.used ?? 0,
                    limit: limit.limit,
                    unit: limit.unitAr,
                    dense: true,
                  ),
              ],
            ),
    );
  }
}

class _EffectiveFeaturesSection extends StatelessWidget {
  const _EffectiveFeaturesSection({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final features = detail.entitlements.features.values.toList()
      ..sort((a, b) {
        final byCategory = a.categoryKey.compareTo(b.categoryKey);
        return byCategory != 0
            ? byCategory
            : a.sortOrder.compareTo(b.sortOrder);
      });

    return DashboardPanel(
      icon: DashboardIcons.featureCatalog,
      title: 'الميزات الفعّالة',
      subtitle: 'كل قيمة ومصدرها — أي رتبة في السلم أنتجتها.',
      child: Column(
        children: [
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      feature.nameAr,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      FeatureValue.label(feature.value, unit: feature.unitAr),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FeatureSourceChip(
                    source: feature.source,
                    blockedBy: feature.blockedBy,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OverridesSection extends StatelessWidget {
  const _OverridesSection({required this.state, required this.detail});

  final PlatformLicensingLoaded state;
  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();

    return DashboardPanel(
      icon: DashboardIcons.locked,
      title: 'التجاوزات',
      subtitle:
          'استثناءات هذا المكتب وحده. لا تُنشأ باقة جديدة لكل تفاوض — يُنشأ صف.',
      trailing: IconButton(
        tooltip: 'إضافة استثناء',
        icon: const Icon(DashboardIcons.add),
        onPressed: () => _add(context, cubit),
      ),
      child: detail.overrides.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.locked,
              title: 'لا توجد استثناءات',
              message: 'المكتب يتبع باقته بالكامل.',
            )
          : Column(
              children: [
                for (final entry in detail.overrides)
                  OverrideTile(
                    entry: entry,
                    onClear: () => _clear(context, cubit, entry),
                  ),
              ],
            ),
    );
  }

  Future<void> _add(BuildContext context, PlatformLicensingCubit cubit) async {
    final result = await showDialog<_OverrideDraft>(
      context: context,
      builder: (context) => _OverrideDialog(catalog: state.catalog),
    );
    if (result == null || !context.mounted) return;
    await cubit.setOverride(
      detail.officeId,
      result.featureKey,
      result.value,
      result.reason,
      expiresAt: result.expiresAt,
    );
  }

  Future<void> _clear(
    BuildContext context,
    PlatformLicensingCubit cubit,
    FeatureOverride entry,
  ) async {
    final reason = await promptForReason(
      context,
      title: 'إزالة الاستثناء',
      description:
          'سيعود «${entry.nameAr}» إلى قيمة الباقة. الإزالة مسجَّلة في السجل.',
      confirmLabel: 'إزالة',
    );
    if (reason == null || !context.mounted) return;
    await cubit.clearOverride(detail.officeId, entry.featureKey, reason);
  }
}

class _OverrideDraft {
  const _OverrideDraft({
    required this.featureKey,
    required this.value,
    required this.reason,
    this.expiresAt,
  });

  final String featureKey;
  final Object? value;
  final String reason;
  final DateTime? expiresAt;
}

class _OverrideDialog extends StatefulWidget {
  const _OverrideDialog({required this.catalog});

  final FeatureCatalog catalog;

  @override
  State<_OverrideDialog> createState() => _OverrideDialogState();
}

class _OverrideDialogState extends State<_OverrideDialog> {
  CatalogFeature? _feature;
  Object? _value;
  DateTime? _expiresAt;
  final _reason = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features =
        widget.catalog.features.where((f) => f.status != 'hidden').toList()
          ..sort((a, b) => a.nameAr.compareTo(b.nameAr));

    return AlertDialog(
      title: const Text('استثناء لهذا المكتب'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _feature?.key,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'الميزة',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final f in features)
                    DropdownMenuItem(value: f.key, child: Text(f.nameAr)),
                ],
                validator: (v) => v == null ? 'اختر ميزة' : null,
                onChanged: (key) => setState(() {
                  _feature = features.firstWhere((f) => f.key == key);
                  _value = _feature!.defaultValue;
                }),
              ),
              if (_feature != null) ...[
                const SizedBox(height: AppSpacing.medium),
                Row(
                  children: [
                    const Expanded(child: Text('القيمة')),
                    FeatureValueField(
                      feature: _feature!,
                      value: _value,
                      onChanged: (v) => setState(() => _value = v),
                    ),
                  ],
                ),
                if (_feature!.requires.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                    child: Text(
                      // The trap worth naming before they hit it.
                      'تتطلب: ${_feature!.requires.join('، ')}. الاستثناء يُحترم '
                      'لكن التبعية تُسقِطه إن لم تكن مفعّلة.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _reason,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'السبب',
                  hintText: 'تنازل تجاري، تمديد، تعويض…',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v ?? '').trim().length < 8
                    ? 'اكتب سببًا واضحًا (٨ أحرف على الأقل)'
                    : null,
              ),
              const SizedBox(height: AppSpacing.small),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiresAt == null
                          ? 'دائم'
                          : 'ينتهي في ${licensingDate(_expiresAt)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 1095),
                        ),
                        initialDate: DateTime.now().add(
                          const Duration(days: 90),
                        ),
                      );
                      if (picked != null) setState(() => _expiresAt = picked);
                    },
                    child: const Text('تحديد انتهاء'),
                  ),
                  if (_expiresAt != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _expiresAt = null),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(
              _OverrideDraft(
                featureKey: _feature!.key,
                value: _value,
                reason: _reason.text.trim(),
                expiresAt: _expiresAt,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _InvoicesSection extends StatelessWidget {
  const _InvoicesSection({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      icon: DashboardIcons.billing,
      title: 'الفوترة',
      child: detail.invoices.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.billing,
              title: 'لا توجد فواتير',
            )
          : Column(
              children: [
                for (final invoice in detail.invoices)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(invoice.invoiceNumber),
                    subtitle: Text(
                      '${licensingDate(invoice.periodStart)} → '
                      '${licensingDate(invoice.periodEnd)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(licensingMoney(invoice.total, invoice.currency)),
                        const SizedBox(width: AppSpacing.small),
                        StatusChip(label: invoice.statusLabelAr),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DashboardPanel(
      icon: DashboardIcons.audit,
      title: 'النشاط',
      subtitle: 'شريحة هذا المكتب من سجل التغييرات.',
      child: detail.activity.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.audit,
              title: 'لا توجد تغييرات مسجّلة',
            )
          : Column(
              children: [
                for (final entry in detail.activity.take(20))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            licensingDate(entry.createdAt),
                            style: text.labelSmall?.copyWith(
                              color: DashboardColors.mutedInk(context),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.actionLabelAr} — ${entry.entityLabelAr} '
                            '«${entry.entityRef}»'
                            '${entry.reason.isEmpty ? '' : ' · ${entry.reason}'}',
                            style: text.bodySmall,
                          ),
                        ),
                        Text(
                          entry.actorLabel,
                          style: text.labelSmall?.copyWith(
                            color: DashboardColors.mutedInk(context),
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
