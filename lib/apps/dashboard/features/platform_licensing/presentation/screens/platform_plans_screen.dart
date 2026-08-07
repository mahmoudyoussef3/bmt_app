import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/master_detail_layout.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';
import '../widgets/plan_editor_dialog.dart';

/// الخطط والباقات — the plan builder.
///
/// Master/detail: the plan list on one side, and on the other the catalog
/// grouped by category with a control per row typed by `value_type`.
///
/// The sentence this screen has to keep saying is that a save takes effect
/// **immediately for every subscribed office** — the resolver reads plan values
/// at resolution time and there is no per-office copy to sync — and that the
/// state it replaced is kept as a revision.
///
/// The edit buffer lives *here*, not in the detail panel, for one reason: the
/// plan list has to know the buffer is dirty before it lets the operator move
/// to another plan. A draft owned by the panel is a draft the list can only
/// discard silently.
class PlatformPlansScreen extends StatefulWidget {
  const PlatformPlansScreen({super.key});

  @override
  State<PlatformPlansScreen> createState() => _PlatformPlansScreenState();
}

class _PlatformPlansScreenState extends State<PlatformPlansScreen> {
  /// The working copy of the selected plan's feature map. A key that is ABSENT
  /// means "fall through to the catalog default" — a different statement from
  /// setting it false — and the server replaces the map wholesale, so this must
  /// always be the complete picture.
  Map<String, Object?> _draft = {};
  String? _draftPlanId;

  String _planQuery = '';
  String? _planStatusFilter;

  String _featureQuery = '';
  bool _modifiedOnly = false;

  /// Guards the one-shot "open the first plan" so a later manual close does not
  /// immediately re-open it.
  bool _autoSelected = false;

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        _syncDraft(state);
        _autoSelectFirstPlan(context, state);

        final detail = state.selectedPlan;
        final changed = detail == null
            ? const <String>{}
            : _changedKeys(detail);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlansHeader(state: state, onCreate: () => _createPlan(context)),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: MasterDetailLayout(
                masterFlex: 2,
                detailFlex: 4,
                placeholderTitle: 'اختر باقة لعرض ميزاتها',
                placeholderSubtitle:
                    'التعديل يسري فورًا على كل مكتب مشترك في الباقة.',
                master: _PlanList(
                  plans: state.plans,
                  selectedId: detail?.plan.id,
                  query: _planQuery,
                  statusFilter: _planStatusFilter,
                  dirtyCount: changed.length,
                  onQuery: (q) => setState(() => _planQuery = q),
                  onStatus: (s) => setState(() => _planStatusFilter = s),
                  onSelect: (id) => _selectPlan(context, state, id),
                  onCreate: () => _createPlan(context),
                ),
                detail: detail == null
                    ? null
                    : _PlanDetailPanel(
                        state: state,
                        detail: detail,
                        draft: _draft,
                        changedKeys: changed,
                        featureQuery: _featureQuery,
                        modifiedOnly: _modifiedOnly,
                        onFeatureQuery: (q) =>
                            setState(() => _featureQuery = q),
                        onModifiedOnly: (v) =>
                            setState(() => _modifiedOnly = v),
                        onValueChanged: (key, value) =>
                            setState(() => _draft[key] = value),
                        onValueCleared: (key) =>
                            setState(() => _draft.remove(key)),
                        onSave: () => _saveValues(context, detail),
                        onDiscard: () =>
                            setState(() => _draft = {...detail.values}),
                        onEdit: () => _editPlan(context, detail.plan),
                        onClone: () => _clonePlan(context, detail.plan),
                        onStatusChange: (status) =>
                            _changeStatus(context, detail.plan, status),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Draft bookkeeping ──────────────────────────────────────────────────────

  /// Re-points the buffer when — and only when — the operator moved to a
  /// different plan, so a background refresh of the console cannot silently
  /// discard unsaved edits.
  ///
  /// Runs during build and assigns without `setState` deliberately: the frame
  /// being built is the one that needs the new value, and the assignment is
  /// idempotent for a given selection.
  void _syncDraft(PlatformLicensingLoaded state) {
    final detail = state.selectedPlan;
    if (detail == null) {
      _draftPlanId = null;
      _draft = {};
      return;
    }
    if (detail.plan.id != _draftPlanId) {
      _draftPlanId = detail.plan.id;
      _draft = {...detail.values};
    }
  }

  /// Which keys differ from what is stored. Presence matters as much as value:
  /// removing a key ("follow the catalog default") is an edit, and both sides
  /// stringify to `null` when compared naively.
  Set<String> _changedKeys(PlanDetail detail) {
    final saved = detail.values;
    final keys = {...saved.keys, ..._draft.keys};
    return keys
        .where(
          (key) =>
              saved.containsKey(key) != _draft.containsKey(key) ||
              '${saved[key]}' != '${_draft[key]}',
        )
        .toSet();
  }

  /// A master/detail screen whose detail is empty on arrival wastes two thirds
  /// of the console, so the first plan opens itself.
  void _autoSelectFirstPlan(
    BuildContext context,
    PlatformLicensingLoaded state,
  ) {
    if (_autoSelected ||
        state.selectedPlan != null ||
        state.plans.isEmpty ||
        state.isBusy) {
      return;
    }
    _autoSelected = true;
    final first = _sortPlans(state.plans).first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlatformLicensingCubit>().selectPlan(first.id);
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _selectPlan(
    BuildContext context,
    PlatformLicensingLoaded state,
    String planId,
  ) async {
    final detail = state.selectedPlan;
    if (detail != null && detail.plan.id == planId) return;

    if (detail != null) {
      final changed = _changedKeys(detail);
      if (changed.isNotEmpty) {
        final leave = await _confirmDiscard(context, changed.length);
        if (leave != true || !context.mounted) return;
      }
    }
    await context.read<PlatformLicensingCubit>().selectPlan(planId);
  }

  Future<bool?> _confirmDiscard(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديلات غير محفوظة'),
        content: Text(
          'على هذه الباقة $count تعديل لم يُحفظ. الانتقال إلى باقة أخرى '
          'يتخلّى عنها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('البقاء هنا'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تجاهل والانتقال'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveValues(BuildContext context, PlanDetail detail) async {
    final cubit = context.read<PlatformLicensingCubit>();
    final reason = await promptForReason(
      context,
      title: 'حفظ تعديلات الباقة',
      description:
          'سيسري التعديل فورًا على كل مكتب مشترك في هذه الباقة، وستُحفظ الحالة '
          'السابقة كنسخة في السجل يمكن الرجوع إليها.',
      confirmLabel: 'حفظ',
    );
    if (reason == null) return;

    await cubit.savePlanValues(detail.plan.id, _draft, reason);
    if (!mounted) return;

    // Re-seed the buffer from what the server actually stored, so a value it
    // normalised does not read as an unsaved edit for the rest of the session.
    final next = cubit.state;
    if (next is PlatformLicensingLoaded &&
        next.selectedPlan?.plan.id == detail.plan.id) {
      setState(() => _draft = {...next.selectedPlan!.values});
    }
  }

  Future<void> _createPlan(BuildContext context) async {
    final cubit = context.read<PlatformLicensingCubit>();
    final payload = await showPlanEditorDialog(context);
    if (payload == null) return;
    await cubit.savePlanDetails(payload);
  }

  Future<void> _editPlan(BuildContext context, LicensingPlan plan) async {
    final cubit = context.read<PlatformLicensingCubit>();
    final payload = await showPlanEditorDialog(context, plan: plan);
    if (payload == null) return;
    await cubit.savePlanDetails(payload);
  }

  Future<void> _clonePlan(BuildContext context, LicensingPlan plan) async {
    final cubit = context.read<PlatformLicensingCubit>();
    final clone = await showClonePlanDialog(context, plan: plan);
    if (clone == null) return;
    await cubit.clonePlan(plan.id, clone.key, clone.name);
  }

  Future<void> _changeStatus(
    BuildContext context,
    LicensingPlan plan,
    String status,
  ) async {
    final cubit = context.read<PlatformLicensingCubit>();
    final (title, description, confirm) = switch (status) {
      'archived' => (
        'أرشفة الباقة',
        // Archiving is not deletion, and the difference is the whole reason an
        // operator hesitates over this button.
        'المكاتب المشتركة تكمل على هذه الباقة بلا أي تغيير، ولا يمكن تعيينها '
            'لمكتب جديد بعد الأرشفة.',
        'أرشفة',
      ),
      'active' when plan.status == 'draft' => (
        'نشر الباقة',
        'تصبح الباقة قابلة للتعيين للمكاتب'
            '${plan.isPublic ? '، وتظهر ضمن الباقات المعروضة' : ''}.',
        'نشر',
      ),
      'active' => (
        'إعادة تفعيل الباقة',
        'تعود الباقة قابلة للتعيين لمكاتب جديدة.',
        'تفعيل',
      ),
      _ => ('تغيير حالة الباقة', null, 'تأكيد'),
    };

    final reason = await promptForReason(
      context,
      title: title,
      description: description,
      confirmLabel: confirm,
    );
    if (reason == null) return;
    await cubit.savePlanDetails({
      'id': plan.id,
      'status': status,
      'reason': reason,
    });
  }
}

/// Active first, then drafts, then the archive — the order an operator reasons
/// about plans in, rather than insertion order.
List<LicensingPlan> _sortPlans(List<LicensingPlan> plans) {
  int rank(LicensingPlan p) => switch (p.status) {
    'active' => 0,
    'draft' => 1,
    _ => 2,
  };
  return [...plans]..sort((a, b) {
    final byStatus = rank(a).compareTo(rank(b));
    if (byStatus != 0) return byStatus;
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    return byOrder != 0 ? byOrder : a.nameAr.compareTo(b.nameAr);
  });
}

Color _planStatusColor(BuildContext context, LicensingPlan plan) {
  final scheme = Theme.of(context).colorScheme;
  return switch (plan.status) {
    'active' => scheme.secondary,
    'draft' => scheme.tertiary,
    _ => scheme.outline,
  };
}

String _officeStatusLabelAr(String status) => switch (status) {
  'trialing' => 'فترة تجريبية',
  'active' => 'نشطة',
  'past_due' => 'متأخرة السداد',
  'grace' => 'مهلة أخيرة',
  'suspended' => 'موقوفة',
  'cancelled' => 'ملغاة',
  'expired' => 'منتهية',
  _ => status,
};

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

class _PlansHeader extends StatelessWidget {
  const _PlansHeader({required this.state, required this.onCreate});

  final PlatformLicensingLoaded state;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plans = state.plans;
    final catalog = state.catalog;

    final active = plans.where((p) => p.status == 'active').length;
    final drafts = plans.where((p) => p.status == 'draft').length;
    final archived = plans.where((p) => p.isArchived).length;
    final offices = plans.fold<int>(0, (sum, p) => sum + p.officeCount);
    final inUse = plans.where((p) => p.officeCount > 0).length;

    // Only offices on a plan with a published price can be counted: a
    // negotiated contract has no figure here to add, and inventing one would
    // make this tile a guess wearing a currency symbol.
    final contracted = plans
        .where((p) => p.priceMonthly != null)
        .fold<num>(0, (sum, p) => sum + p.priceMonthly! * p.officeCount);
    final negotiated = plans
        .where((p) => p.priceMonthly == null)
        .fold<int>(0, (sum, p) => sum + p.officeCount);

    return DashboardModuleHeader(
      icon: DashboardIcons.plans,
      title: 'الخطط والباقات',
      subtitle:
          'ما تبيعه المنصة للمكاتب. الباقة قالب بلا سلوك: كل ما "تفعله" '
          'قيمة يقرأها المُحلِّل، ولهذا يمكن تعديلها وهي حيّة.',
      actions: [
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(DashboardIcons.add, size: 18),
          label: const Text('باقة جديدة'),
        ),
      ],
      // Foldable, and nested bare because the header slot is already a card
      // with its own inset: on a short console window these four tiles are the
      // difference between a workable plan editor and a letterbox.
      child: DashboardCollapsibleSection.bare(
        sectionId: DashboardSectionIds.platformPlansKpis,
        title: 'ملخّص الباقات',
        icon: DashboardIcons.trend,
        headerPadding: EdgeInsets.zero,
        bodyPadding: const EdgeInsets.only(top: AppSpacing.small),
        collapsedSummary: DashboardSectionSummary(
          items: [
            '${plans.length} باقة',
            '$offices مكتب مشترك',
            licensingMoney(contracted),
          ],
        ),
        child: DashboardKpiGrid(
          children: [
            DashboardKpiCard(
              icon: DashboardIcons.plans,
              label: 'الباقات',
              value: '${plans.length}',
              // Two figures, not four: a KPI tile has one line, and the list's
              // own filter chips already carry the full status breakdown.
              detail: archived > 0
                  ? '$active نشطة · $archived مؤرشفة'
                  : '$active نشطة · $drafts مسودة',
            ),
            DashboardKpiCard(
              icon: DashboardIcons.platformOffices,
              label: 'مكاتب مشتركة',
              value: '$offices',
              detail: inUse == 0
                  ? 'لا باقة قيد الاستخدام بعد'
                  : 'موزّعة على $inUse باقة',
              color: scheme.secondary,
            ),
            DashboardKpiCard(
              icon: DashboardIcons.payments,
              label: 'إيراد شهري متعاقد',
              value: licensingMoney(contracted),
              detail: negotiated == 0
                  ? 'من الباقات ذات السعر المعلن'
                  : 'عدا $negotiated مكتب بسعر تفاوضي',
              color: scheme.tertiary,
            ),
            DashboardKpiCard(
              icon: DashboardIcons.featureCatalog,
              label: 'ميزات الكتالوج',
              value: '${catalog.features.length}',
              detail:
                  '${catalog.enforcedCount} مطبَّقة · '
                  '${catalog.declaredCount} غير مفعّلة',
              color: catalog.declaredCount > 0 ? scheme.tertiary : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Master — the plan list
// ═══════════════════════════════════════════════════════════════════════════

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.plans,
    required this.selectedId,
    required this.query,
    required this.statusFilter,
    required this.dirtyCount,
    required this.onQuery,
    required this.onStatus,
    required this.onSelect,
    required this.onCreate,
  });

  final List<LicensingPlan> plans;
  final String? selectedId;
  final String query;
  final String? statusFilter;
  final int dirtyCount;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;

  static const _statuses = <String, String>{
    'active': 'نشطة',
    'draft': 'مسودات',
    'archived': 'مؤرشفة',
  };

  List<LicensingPlan> get _visible {
    final q = query.trim().toLowerCase();
    return _sortPlans(
      plans.where((plan) {
        if (statusFilter != null && plan.status != statusFilter) return false;
        if (q.isEmpty) return true;
        return plan.nameAr.contains(q) ||
            plan.key.toLowerCase().contains(q) ||
            plan.nameEn.toLowerCase().contains(q) ||
            plan.taglineAr.contains(q);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    // Scrollable in its own right: the master column is as tall as the console
    // and the list is not, so anything past the fold has to be reachable
    // without dragging the page.
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
      child: DashboardPanel(
        sectionId: DashboardSectionIds.platformPlansList,
        icon: DashboardIcons.plans,
        title: 'الباقات',
        subtitle: visible.length == plans.length
            ? '${plans.length} باقة'
            : '${visible.length} من ${plans.length} باقة',
        trailing: IconButton(
          tooltip: 'باقة جديدة',
          icon: const Icon(DashboardIcons.add),
          onPressed: onCreate,
        ),
        collapsedSummary: DashboardSectionSummary(
          items: [
            '${visible.length} باقة',
            if (statusFilter != null) _statuses[statusFilter] ?? statusFilter!,
            if (query.trim().isNotEmpty) 'بحث: ${query.trim()}',
            if (dirtyCount > 0) '$dirtyCount تعديل غير محفوظ',
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DebouncedSearchField(
              initialValue: query,
              hintText: 'ابحث باسم الباقة أو مفتاحها',
              onChanged: onQuery,
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.xSmall,
              runSpacing: AppSpacing.xSmall,
              children: [
                FilterChip(
                  label: Text('الكل (${plans.length})'),
                  selected: statusFilter == null,
                  onSelected: (_) => onStatus(null),
                ),
                for (final entry in _statuses.entries)
                  if (plans.any((p) => p.status == entry.key))
                    FilterChip(
                      label: Text(
                        '${entry.value} '
                        '(${plans.where((p) => p.status == entry.key).length})',
                      ),
                      selected: statusFilter == entry.key,
                      onSelected: (_) => onStatus(entry.key),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            if (visible.isEmpty)
              DashboardEmptyState(
                icon: DashboardIcons.plans,
                title: plans.isEmpty ? 'لا توجد باقات' : 'لا باقة تطابق البحث',
                message: plans.isEmpty
                    ? 'أنشئ باقة لتبدأ ترخيص المكاتب.'
                    : 'جرّب مصطلحًا آخر أو أزل عوامل التصفية.',
                action: plans.isEmpty
                    ? FilledButton.tonalIcon(
                        onPressed: onCreate,
                        icon: const Icon(DashboardIcons.add, size: 18),
                        label: const Text('باقة جديدة'),
                      )
                    : TextButton(
                        onPressed: () => onStatus(null),
                        child: const Text('عرض كل الباقات'),
                      ),
              )
            else
              for (final plan in visible)
                _PlanTile(
                  plan: plan,
                  selected: plan.id == selectedId,
                  dirtyCount: plan.id == selectedId ? dirtyCount : 0,
                  onTap: () => onSelect(plan.id),
                ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.dirtyCount,
    required this.onTap,
  });

  final LicensingPlan plan;
  final bool selected;
  final int dirtyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.primary;
    final statusColor = _planStatusColor(context, plan);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withAlpha(20)
                  : DashboardColors.well(context),
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? accent.withAlpha(140)
                    : DashboardColors.border(context),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tooltip(
                      message: plan.statusLabelAr,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        plan.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (dirtyCount > 0)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AppSpacing.xSmall,
                        ),
                        child: Tooltip(
                          message: '$dirtyCount تعديل غير محفوظ',
                          child: Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                            color: scheme.tertiary,
                          ),
                        ),
                      ),
                    // Only the states worth flagging get a pill: five identical
                    // "نشطة" chips are noise that hides the one draft.
                    if (plan.status != 'active')
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AppSpacing.xSmall,
                        ),
                        child: StatusChip(
                          label: plan.statusLabelAr,
                          color: statusColor.withAlpha(24),
                          textColor: statusColor,
                        ),
                      ),
                  ],
                ),
                if (plan.taglineAr.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    plan.taglineAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.small),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.small,
                        runSpacing: 4,
                        children: [
                          _Meta(
                            icon: DashboardIcons.platformOffices,
                            label: plan.officeCount == 0
                                ? 'بلا مكاتب'
                                : '${plan.officeCount} مكتب',
                          ),
                          if (plan.trialDays > 0)
                            _Meta(
                              icon: DashboardIcons.time,
                              label: 'تجربة ${plan.trialDays} يوم',
                            ),
                          _Meta(
                            icon: plan.isPublic
                                ? Icons.storefront_outlined
                                : DashboardIcons.locked,
                            label: plan.isPublic ? 'معروضة' : 'بالتعيين فقط',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    _PriceLabel(plan: plan),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The figure a plan is sold at, given the weight it has in the decision —
/// rather than buried as the third item in a row of grey metadata.
class _PriceLabel extends StatelessWidget {
  const _PriceLabel({required this.plan});

  final LicensingPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (plan.priceMonthly == null) {
      return Text(
        'سعر تفاوضي',
        style: theme.textTheme.labelMedium?.copyWith(
          color: DashboardColors.mutedInk(context),
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          licensingMoney(plan.priceMonthly, plan.currency),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '/ شهر',
          style: theme.textTheme.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
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
        Icon(icon, size: 13, color: DashboardColors.mutedInk(context)),
        const SizedBox(width: 4),
        // Flexible, because a Wrap hands its children the full line width and
        // then lets them size themselves: an unconstrained label is how a
        // narrow master column clips its own metadata.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Detail — one plan
// ═══════════════════════════════════════════════════════════════════════════

class _PlanDetailPanel extends StatelessWidget {
  const _PlanDetailPanel({
    required this.state,
    required this.detail,
    required this.draft,
    required this.changedKeys,
    required this.featureQuery,
    required this.modifiedOnly,
    required this.onFeatureQuery,
    required this.onModifiedOnly,
    required this.onValueChanged,
    required this.onValueCleared,
    required this.onSave,
    required this.onDiscard,
    required this.onEdit,
    required this.onClone,
    required this.onStatusChange,
  });

  final PlatformLicensingLoaded state;
  final PlanDetail detail;
  final Map<String, Object?> draft;
  final Set<String> changedKeys;
  final String featureQuery;
  final bool modifiedOnly;
  final ValueChanged<String> onFeatureQuery;
  final ValueChanged<bool> onModifiedOnly;
  final void Function(String key, Object? value) onValueChanged;
  final ValueChanged<String> onValueCleared;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onEdit;
  final VoidCallback onClone;
  final ValueChanged<String> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();

    final header = _PlanHeaderCard(
      detail: detail,
      changedCount: changedKeys.length,
      onSave: onSave,
      onDiscard: onDiscard,
      onPreview: () => cubit.previewPlan(detail.plan.id),
      onEdit: onEdit,
      onClone: onClone,
      onStatusChange: onStatusChange,
    );

    final tabs = TabBarView(
      children: [
        _FeatureValuesTab(
          catalog: state.catalog,
          draft: draft,
          saved: detail.values,
          changedKeys: changedKeys,
          preview: state.planPreview,
          query: featureQuery,
          modifiedOnly: modifiedOnly,
          onQuery: onFeatureQuery,
          onModifiedOnly: onModifiedOnly,
          onChanged: onValueChanged,
          onCleared: onValueCleared,
          onClosePreview: cubit.clearPlanPreview,
        ),
        _PlanOfficesTab(detail: detail),
        _PlanRevisionsTab(detail: detail, catalog: state.catalog),
      ],
    );

    return DefaultTabController(
      // Keyed by plan: moving to another plan starts on its features again
      // rather than on whichever tab the previous plan was left open at.
      key: ValueKey(detail.plan.id),
      length: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The plan card plus a usable tab body needs real height. On a short
          // console window there is not enough of it, and a fixed header over a
          // flexed body would simply clip — so below the threshold the whole
          // pane scrolls and the tab body keeps a workable minimum instead.
          final roomy = constraints.maxHeight >= _detailBreakpoint;
          final column = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: roomy ? MainAxisSize.max : MainAxisSize.min,
            children: [
              header,
              const SizedBox(height: AppSpacing.medium),
              if (roomy)
                Expanded(child: tabs)
              else
                SizedBox(height: _compactTabHeight, child: tabs),
            ],
          );
          return roomy ? column : SingleChildScrollView(child: column);
        },
      ),
    );
  }
}

/// Below this the detail pane stops flexing and starts scrolling.
const double _detailBreakpoint = 620;
const double _compactTabHeight = 460;

class _PlanHeaderCard extends StatelessWidget {
  const _PlanHeaderCard({
    required this.detail,
    required this.changedCount,
    required this.onSave,
    required this.onDiscard,
    required this.onPreview,
    required this.onEdit,
    required this.onClone,
    required this.onStatusChange,
  });

  final PlanDetail detail;
  final int changedCount;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onClone;
  final ValueChanged<String> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plan = detail.plan;
    final statusColor = _planStatusColor(context, plan);
    final isDirty = changedCount > 0;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                      ),
                      child: Icon(
                        DashboardIcons.plansActive,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  plan.nameAr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              StatusChip(
                                label: plan.statusLabelAr,
                                color: statusColor.withAlpha(24),
                                textColor: statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${plan.key} · مراجعة ${plan.revision}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: DashboardColors.mutedInk(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.xSmall,
                      runSpacing: AppSpacing.xSmall,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: isDirty ? onSave : null,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(isDirty ? 'حفظ ($changedCount)' : 'حفظ'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onPreview,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('معاينة'),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'إجراءات الباقة',
                          icon: const Icon(Icons.more_horiz_rounded),
                          onSelected: (action) => switch (action) {
                            'edit' => onEdit(),
                            'clone' => onClone(),
                            _ => onStatusChange(action),
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit_outlined),
                                title: Text('تعديل البيانات'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'clone',
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.copy_rounded),
                                title: Text('نسخ'),
                              ),
                            ),
                            if (plan.status == 'draft')
                              const PopupMenuItem(
                                value: 'active',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.publish_rounded),
                                  title: Text('نشر الباقة'),
                                ),
                              ),
                            if (plan.isArchived)
                              const PopupMenuItem(
                                value: 'active',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.unarchive_outlined),
                                  title: Text('إعادة التفعيل'),
                                ),
                              )
                            else
                              const PopupMenuItem(
                                value: 'archived',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.archive_outlined),
                                  title: Text('أرشفة'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.xSmall,
                  children: [
                    _Fact(
                      icon: DashboardIcons.payments,
                      label: plan.priceMonthly == null
                          ? 'سعر تفاوضي'
                          : '${licensingMoney(plan.priceMonthly, plan.currency)} / شهر',
                    ),
                    if (plan.priceYearly != null)
                      _Fact(
                        icon: DashboardIcons.billing,
                        label:
                            '${licensingMoney(plan.priceYearly, plan.currency)} / سنة',
                      ),
                    _Fact(
                      icon: DashboardIcons.time,
                      label: plan.trialDays > 0
                          ? 'تجربة ${plan.trialDays} يوم'
                          : 'بلا فترة تجريبية',
                    ),
                    _Fact(
                      icon: DashboardIcons.platformOffices,
                      label: plan.officeCount == 0
                          ? 'لا مكتب على هذه الباقة'
                          : '${plan.officeCount} مكتب مشترك',
                    ),
                    _Fact(
                      icon: plan.isPublic
                          ? Icons.storefront_outlined
                          : DashboardIcons.locked,
                      label: plan.isPublic ? 'معروضة للمكاتب' : 'بالتعيين فقط',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (plan.isArchived)
            _Banner(
              icon: Icons.archive_outlined,
              color: scheme.error,
              // Archiving is not deletion: the offices already on it keep
              // resolving exactly as before.
              message:
                  'باقة مؤرشفة — المكاتب المشتركة تعمل كما هي، ولا يمكن '
                  'تعيينها لمكتب جديد.',
            ),
          if (isDirty)
            _Banner(
              icon: Icons.edit_note_rounded,
              color: scheme.tertiary,
              message:
                  '$changedCount تعديل غير محفوظ. لا يسري أي منها على أي مكتب '
                  'قبل الحفظ.',
              actions: [
                TextButton(onPressed: onDiscard, child: const Text('تجاهل')),
                FilledButton(onPressed: onSave, child: const Text('حفظ')),
              ],
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.small,
              end: AppSpacing.small,
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                _CountTab(
                  label: 'الميزات',
                  count: detail.values.length,
                  tooltip: 'قيم مضبوطة في هذه الباقة',
                ),
                _CountTab(label: 'المكاتب', count: detail.offices.length),
                _CountTab(label: 'السجل', count: detail.revisions.length),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountTab extends StatelessWidget {
  const _CountTab({required this.label, required this.count, this.tooltip});

  final String label;
  final int count;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tab = Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: AppSpacing.xSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return tooltip == null ? tab : Tooltip(message: tooltip!, child: tab);
  }
}

/// A full-width strip under the header: the plan is archived, or the buffer is
/// dirty. Both are facts the operator must not be able to scroll away from.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
    this.actions = const [],
  });

  final IconData icon;
  final Color color;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border(top: BorderSide(color: color.withAlpha(60))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DashboardColors.mutedInk(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Features tab
// ═══════════════════════════════════════════════════════════════════════════

class _FeatureValuesTab extends StatelessWidget {
  const _FeatureValuesTab({
    required this.catalog,
    required this.draft,
    required this.saved,
    required this.changedKeys,
    required this.query,
    required this.modifiedOnly,
    required this.onQuery,
    required this.onModifiedOnly,
    required this.onChanged,
    required this.onCleared,
    required this.onClosePreview,
    this.preview,
  });

  final FeatureCatalog catalog;
  final Map<String, Object?> draft;
  final Map<String, Object?> saved;
  final Set<String> changedKeys;
  final String query;
  final bool modifiedOnly;
  final ValueChanged<String> onQuery;
  final ValueChanged<bool> onModifiedOnly;
  final Map<String, dynamic>? preview;
  final void Function(String key, Object? value) onChanged;
  final ValueChanged<String> onCleared;
  final VoidCallback onClosePreview;

  bool _matches(CatalogFeature feature) {
    if (feature.status == 'hidden') return false;
    if (modifiedOnly && !draft.containsKey(feature.key)) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return feature.nameAr.contains(q) ||
        feature.key.toLowerCase().contains(q) ||
        feature.nameEn.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final visible = catalog.features.where(_matches).toList();

    // Grouped by the catalog's own category order, with anything whose category
    // is unknown collected at the end instead of silently dropped.
    final grouped = <String, List<CatalogFeature>>{};
    for (final feature in visible) {
      grouped.putIfAbsent(feature.categoryKey, () => []).add(feature);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    final orderedKeys = [
      for (final category in catalog.categories)
        if (grouped.containsKey(category.key)) category.key,
      ...grouped.keys.where(
        (key) => !catalog.categories.any((c) => c.key == key),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeatureToolbar(
          query: query,
          modifiedOnly: modifiedOnly,
          onQuery: onQuery,
          onModifiedOnly: onModifiedOnly,
          shown: visible.length,
          total: catalog.features.where((f) => f.status != 'hidden').length,
          setCount: draft.length,
        ),
        const SizedBox(height: AppSpacing.medium),
        Expanded(
          child: ListView(
            children: [
              if (preview != null) ...[
                _PreviewPanel(preview: preview!, onClose: onClosePreview),
                const SizedBox(height: AppSpacing.medium),
              ],
              if (visible.isEmpty)
                DashboardPanel(
                  icon: DashboardIcons.featureCatalog,
                  title: 'الميزات',
                  child: DashboardEmptyState(
                    icon: DashboardIcons.featureCatalog,
                    title: modifiedOnly
                        ? 'لا قيمة مضبوطة في هذه الباقة'
                        : 'لا ميزة تطابق البحث',
                    message: modifiedOnly
                        ? 'الباقة تتبع الكتالوج بالكامل — كل ميزة على قيمتها الافتراضية.'
                        : 'جرّب اسمًا آخر أو مفتاح الميزة.',
                    action: modifiedOnly
                        ? TextButton(
                            onPressed: () => onModifiedOnly(false),
                            child: const Text('عرض كل الميزات'),
                          )
                        : null,
                  ),
                )
              else
                for (final key in orderedKeys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: _CategorySection(
                      categoryKey: key,
                      categoryName: catalog.categoryName(key),
                      features: grouped[key]!,
                      draft: draft,
                      saved: saved,
                      changedKeys: changedKeys,
                      onChanged: onChanged,
                      onCleared: onCleared,
                    ),
                  ),
              Text(
                // The distinction that trips everybody up, said once, in place.
                'ميزة بلا قيمة في الباقة ترجع إلى الافتراضي المسجَّل في الكتالوج — '
                'وهذا ليس نفس معنى «مُعطَّلة».',
                style: text.bodySmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureToolbar extends StatelessWidget {
  const _FeatureToolbar({
    required this.query,
    required this.modifiedOnly,
    required this.onQuery,
    required this.onModifiedOnly,
    required this.shown,
    required this.total,
    required this.setCount,
  });

  final String query;
  final bool modifiedOnly;
  final ValueChanged<String> onQuery;
  final ValueChanged<bool> onModifiedOnly;
  final int shown;
  final int total;
  final int setCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: DebouncedSearchField(
              initialValue: query,
              hintText: 'ابحث في الميزات',
              onChanged: onQuery,
            ),
          ),
          FilterChip(
            label: Text('المضبوطة في الباقة ($setCount)'),
            selected: modifiedOnly,
            onSelected: onModifiedOnly,
          ),
          Text(
            'يُعرض $shown من $total',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// The resolver's own output for a hypothetical office on this plan.
class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.preview, required this.onClose});

  final Map<String, dynamic> preview;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final entries = preview.entries.toList();
    return DashboardPanel(
      sectionId: DashboardSectionIds.platformPlansPreview,
      icon: Icons.visibility_outlined,
      title: 'معاينة الصلاحيات الفعلية',
      subtitle:
          'ناتج المُحلِّل نفسه على مكتب افتراضي بهذه الباقة وبلا استثناءات.',
      trailing: IconButton(
        tooltip: 'إغلاق المعاينة',
        icon: const Icon(Icons.close_rounded, size: 18),
        onPressed: onClose,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final entry in entries.take(60))
                _PreviewPill(
                  label: '${(entry.value as Map)['name_ar'] ?? entry.key}',
                  value: FeatureValue.label((entry.value as Map)['value']),
                ),
            ],
          ),
          if (entries.length > 60)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                'و${entries.length - 60} ميزة أخرى.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.categoryKey,
    required this.categoryName,
    required this.features,
    required this.draft,
    required this.saved,
    required this.changedKeys,
    required this.onChanged,
    required this.onCleared,
  });

  final String categoryKey;
  final String categoryName;
  final List<CatalogFeature> features;
  final Map<String, Object?> draft;
  final Map<String, Object?> saved;
  final Set<String> changedKeys;
  final void Function(String key, Object? value) onChanged;
  final ValueChanged<String> onCleared;

  @override
  Widget build(BuildContext context) {
    final setHere = features.where((f) => draft.containsKey(f.key)).length;
    final changedHere = features
        .where((f) => changedKeys.contains(f.key))
        .length;

    return DashboardPanel(
      sectionId: DashboardSectionIds.platformPlanCategory(categoryKey),
      icon: DashboardIcons.featureCatalog,
      title: categoryName,
      subtitle: '${features.length} ميزة · $setHere مضبوطة في هذه الباقة',
      collapsedSummary: DashboardSectionSummary(
        items: [
          '${features.length} ميزة',
          if (setHere > 0) '$setHere مضبوطة',
          if (changedHere > 0) '$changedHere غير محفوظة',
        ],
      ),
      child: Column(
        children: [
          for (final feature in features) ...[
            if (feature != features.first)
              Divider(height: 1, color: DashboardColors.divider(context)),
            _FeatureRow(
              feature: feature,
              value: draft[feature.key],
              isSet: draft.containsKey(feature.key),
              isChanged: changedKeys.contains(feature.key),
              savedLabel: saved.containsKey(feature.key)
                  ? FeatureValue.label(saved[feature.key])
                  : null,
              onChanged: (v) => onChanged(feature.key, v),
              onCleared: () => onCleared(feature.key),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.value,
    required this.isSet,
    required this.isChanged,
    required this.savedLabel,
    required this.onChanged,
    required this.onCleared,
  });

  final CatalogFeature feature;
  final Object? value;
  final bool isSet;
  final bool isChanged;

  /// What is stored for this key right now, when anything is — shown only while
  /// the row is dirty, so "what am I about to change it from?" is answerable
  /// without leaving the screen.
  final String? savedLabel;

  final ValueChanged<Object?> onChanged;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: isChanged
                ? Tooltip(
                    message: savedLabel == null
                        ? 'تعديل غير محفوظ'
                        : 'تعديل غير محفوظ — المحفوظ الآن: $savedLabel',
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!feature.isEnforced) ...[
                      const SizedBox(width: AppSpacing.small),
                      const EnforcementBadge(isEnforced: false),
                    ],
                    if (feature.isKillSwitched) ...[
                      const SizedBox(width: AppSpacing.xSmall),
                      StatusChip(
                        label: 'موقوفة على مستوى المنصة',
                        color: scheme.error.withAlpha(24),
                        textColor: scheme.error,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isSet
                      ? 'مضبوطة في الباقة · ${feature.key}'
                      : 'تتبع الافتراضي '
                            '(${FeatureValue.label(feature.defaultValue)}) · '
                            '${feature.key}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSet
                        ? scheme.primary
                        : DashboardColors.mutedInk(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          // A lane for the control, so a column of switches, number fields and
          // dropdowns lines up instead of stepping in and out with the length
          // of each feature's name. A minimum rather than a fixed width: the
          // limit control (a number field plus a «بلا حدود» chip) is wider than
          // the rest, and clamping it would clip the chip.
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 216),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FeatureValueField(
                feature: feature,
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
          IconButton(
            tooltip: 'إرجاع إلى الافتراضي',
            icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
            onPressed: isSet ? onCleared : null,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Offices + revisions
// ═══════════════════════════════════════════════════════════════════════════

class _PlanOfficesTab extends StatelessWidget {
  const _PlanOfficesTab({required this.detail});

  final PlanDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        DashboardPanel(
          icon: DashboardIcons.platformOffices,
          title: 'المكاتب المشتركة',
          subtitle: detail.offices.isEmpty
              ? 'لا مكتب على هذه الباقة'
              : '${detail.offices.length} مكتب — أي حفظ للميزات يسري عليها فورًا',
          child: detail.offices.isEmpty
              ? const DashboardEmptyState(
                  icon: DashboardIcons.platformOffices,
                  title: 'لا يوجد مكتب على هذه الباقة',
                  message:
                      'تُعيَّن الباقة للمكاتب من شاشة التراخيص، ويمكن تعديلها '
                      'بأمان حتى ذلك الحين.',
                )
              : Column(
                  children: [
                    for (final office in detail.offices)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                            vertical: AppSpacing.small,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardColors.well(context),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSmall,
                            ),
                            border: Border.all(
                              color: DashboardColors.border(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                DashboardIcons.platformOffices,
                                size: 18,
                                color: DashboardColors.mutedInk(context),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              Expanded(
                                child: Text(
                                  office.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              LicenseStatusChip(
                                status: office.status,
                                label: _officeStatusLabelAr(office.status),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
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
    return ListView(
      children: [
        DashboardPanel(
          icon: DashboardIcons.audit,
          title: 'السجل',
          subtitle:
              'تُحفظ نسخة تلقائيًا قبل كل تعديل، وتُقارَن بالحالة الحالية.',
          child: detail.revisions.isEmpty
              ? const DashboardEmptyState(
                  icon: DashboardIcons.audit,
                  title: 'لا توجد نسخ سابقة',
                  message: 'أول تعديل على الباقة ينشئ أول نسخة.',
                )
              : Column(
                  children: [
                    for (final revision in detail.revisions)
                      DashboardCollapsibleSection.bare(
                        sectionId: DashboardSectionIds.platformPlanRevision(
                          revision.id,
                        ),
                        initiallyExpanded: false,
                        icon: DashboardIcons.activity,
                        title: 'نسخة ${revision.revision}',
                        subtitle:
                            '${licensingDate(revision.createdAt)}'
                            '${revision.reason.isEmpty ? '' : ' — ${revision.reason}'}',
                        headerPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.small,
                        ),
                        bodyPadding: const EdgeInsets.only(
                          bottom: AppSpacing.medium,
                        ),
                        child: _RevisionDiff(
                          changes: _changes(revision.features),
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
  List<_Change> _changes(Map<String, dynamic> snapshot) {
    final keys = {...snapshot.keys, ...detail.values.keys};
    final out = <_Change>[];
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
      out.add(
        _Change(
          name: name,
          before: FeatureValue.label(before),
          after: FeatureValue.label(after),
        ),
      );
    }
    return out..sort((a, b) => a.name.compareTo(b.name));
  }
}

class _Change {
  const _Change({
    required this.name,
    required this.before,
    required this.after,
  });

  final String name;
  final String before;
  final String after;
}

/// Two labelled columns rather than an arrow: "before → after" needs a glyph
/// that flips with the reading direction, and a header row says the same thing
/// with no ambiguity in either.
class _RevisionDiff extends StatelessWidget {
  const _RevisionDiff({required this.changes});

  final List<_Change> changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (changes.isEmpty) {
      return Text(
        'لا فروق عن الحالة الحالية.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      );
    }

    Widget cell(String value, {required bool muted, bool header = false}) =>
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: header || !muted ? FontWeight.w700 : FontWeight.w400,
            color: muted ? DashboardColors.mutedInk(context) : null,
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 4, child: cell('الميزة', muted: true, header: true)),
            Expanded(flex: 3, child: cell('قبل', muted: true, header: true)),
            Expanded(flex: 3, child: cell('بعد', muted: true, header: true)),
          ],
        ),
        Divider(
          height: AppSpacing.medium,
          color: DashboardColors.divider(context),
        ),
        for (final change in changes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(flex: 4, child: cell(change.name, muted: false)),
                Expanded(flex: 3, child: cell(change.before, muted: true)),
                Expanded(flex: 3, child: cell(change.after, muted: false)),
              ],
            ),
          ),
      ],
    );
  }
}
