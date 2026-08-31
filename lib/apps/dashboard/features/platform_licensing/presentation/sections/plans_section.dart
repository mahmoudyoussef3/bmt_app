import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_collapsible_section.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import '../widgets/licensing_layout.dart';
import '../widgets/licensing_widgets.dart';
import '../widgets/plan_editor_dialog.dart';

/// الباقات — what the platform sells, and the workspace it is built in.
///
/// **Two screens, not one split pane.** A plan is a product, and the console
/// reads it the way a pricing page does: a gallery of plan cards, each carrying
/// its price, its reach and its own actions. Opening one replaces the gallery
/// with a full-width workspace instead of squeezing a feature editor into two
/// thirds of a column beside a list. That is the single biggest change here —
/// the old layout gave the *list* the room and the *work* the leftovers.
///
/// **Saving stopped being a negotiation.** Every save used to open a modal
/// demanding an eight-character reason. `platform_save_plan` requires none, the
/// revision snapshot is written either way, and the modal was the reason nobody
/// wanted to touch a plan. The note now lives inline in the save bar and is
/// optional.
///
/// It is a *section* rather than a screen: it shares the «الباقات والميزات»
/// destination with the feature catalog, and [tabBar] is the switch between
/// them. The switch rides in the gallery header and disappears once a plan is
/// open — a workspace with a page-level tab strip above it is two navigations
/// competing for the same glance.
///
/// The edit buffer lives *here* rather than in the workspace, because the
/// section has to be able to refuse to leave a plan while the buffer is dirty. A
/// draft owned by the panel is a draft the navigation can only discard silently.
class PlansSection extends StatefulWidget {
  const PlansSection({super.key, required this.state, this.tabBar});

  final PlatformLicensingLoaded state;
  final Widget? tabBar;

  @override
  State<PlansSection> createState() => _PlansSectionState();
}

class _PlansSectionState extends State<PlansSection> {
  /// The working copy of the open plan's feature map. A key that is ABSENT
  /// means "fall through to the catalog default" — a different statement from
  /// setting it false — and the server replaces the map wholesale, so this must
  /// always be the complete picture.
  Map<String, Object?> _draft = {};
  String? _draftPlanId;

  /// The optional line that goes into the revision the save creates.
  final TextEditingController _note = TextEditingController();

  String _planQuery = '';
  String? _planStatusFilter;

  int _tab = 0;
  String _featureQuery = '';
  String? _featureCategory;
  _FeatureView _view = _FeatureView.all;

  /// Bumped when the operator clears the feature filters, so the search field
  /// is rebuilt around an empty controller — its own controller is `late final`
  /// and never re-reads `initialValue`.
  int _featureSearchEpoch = 0;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    _syncDraft(state);
    final detail = state.selectedPlan;

    if (detail == null) {
      return _PlanGallery(
        state: state,
        tabBar: widget.tabBar,
        query: _planQuery,
        statusFilter: _planStatusFilter,
        onQuery: (q) => setState(() => _planQuery = q),
        onStatus: (s) => setState(() => _planStatusFilter = s),
        onOpen: (id) => context.read<PlatformLicensingCubit>().selectPlan(id),
        onCreate: () => _createPlan(context),
        onEdit: (plan) => _editPlan(context, plan),
        onClone: (plan) => _clonePlan(context, plan),
        onStatusChange: (plan, status) => _changeStatus(context, plan, status),
      );
    }

    final changed = _changedKeys(detail);
    return _PlanWorkspace(
      state: state,
      detail: detail,
      draft: _draft,
      changedKeys: changed,
      note: _note,
      tab: _tab,
      featureQuery: _featureQuery,
      featureCategory: _featureCategory,
      featureSearchEpoch: _featureSearchEpoch,
      view: _view,
      onTab: (i) => setState(() => _tab = i),
      onFeatureQuery: (q) => setState(() => _featureQuery = q),
      onFeatureCategory: (c) => setState(() => _featureCategory = c),
      onView: (v) => setState(() => _view = v),
      onResetFilters: () => setState(() {
        _featureQuery = '';
        _featureCategory = null;
        _view = _FeatureView.all;
        _featureSearchEpoch++;
      }),
      onValueChanged: (key, value) => setState(() => _draft[key] = value),
      onValueCleared: (key) => setState(() => _draft.remove(key)),
      onValuesCleared: (keys) =>
          setState(() => _draft.removeWhere((key, _) => keys.contains(key))),
      onSave: () => _saveValues(context, detail),
      onDiscard: () => setState(() => _draft = {...detail.values}),
      onBack: () => _closePlan(context, changed.length),
      onEdit: () => _editPlan(context, detail.plan),
      onClone: () => _clonePlan(context, detail.plan),
      onStatusChange: (status) => _changeStatus(context, detail.plan, status),
    );
  }

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
      _tab = 0;
      _featureQuery = '';
      _featureCategory = null;
      _view = _FeatureView.all;
      _featureSearchEpoch++;
      _note.clear();
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

  Future<void> _closePlan(BuildContext context, int changedCount) async {
    final cubit = context.read<PlatformLicensingCubit>();
    if (changedCount > 0) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تعديلات غير محفوظة'),
          content: Text(
            'على هذه الباقة $changedCount تعديل لم يُحفظ. الخروج منها يتخلّى '
            'عنها.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('البقاء هنا'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تجاهل والخروج'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    cubit.clearPlanSelection();
  }

  Future<void> _saveValues(BuildContext context, PlanDetail detail) async {
    final cubit = context.read<PlatformLicensingCubit>();
    final note = _note.text.trim();

    await cubit.savePlanValues(
      detail.plan.id,
      _draft,

      note.isEmpty ? 'تعديل قيم الباقة من وحدة التحكم' : note,
    );
    if (!mounted) return;

    final next = cubit.state;
    if (next is PlatformLicensingLoaded &&
        next.selectedPlan?.plan.id == detail.plan.id) {
      setState(() {
        _draft = {...next.selectedPlan!.values};
        _note.clear();
      });
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

  /// Publishing and archiving change what the platform can sell, so they still
  /// confirm — but they confirm with the *consequence*, not with a text field.
  Future<void> _changeStatus(
    BuildContext context,
    LicensingPlan plan,
    String status,
  ) async {
    final cubit = context.read<PlatformLicensingCubit>();
    final (title, description, confirm, danger) = switch (status) {
      'archived' => (
        'أرشفة «${plan.nameAr}»',

        plan.officeCount == 0
            ? 'لن تعود قابلة للتعيين لمكتب جديد. لا مكتب عليها الآن، فلا يتأثر أحد.'
            : 'المكاتب الـ${plan.officeCount} المشتركة تكمل عليها بلا أي تغيير، '
                  'ولا يمكن تعيينها لمكتب جديد بعد الأرشفة.',
        'أرشفة',
        true,
      ),
      'active' when plan.status == 'draft' => (
        'نشر «${plan.nameAr}»',
        'تصبح الباقة قابلة للتعيين للمكاتب'
            '${plan.isPublic ? '، وتظهر ضمن الباقات المعروضة' : ''}.',
        'نشر',
        false,
      ),
      'active' => (
        'إعادة تفعيل «${plan.nameAr}»',
        'تعود الباقة قابلة للتعيين لمكاتب جديدة.',
        'تفعيل',
        false,
      ),
      _ => ('تغيير حالة الباقة', '', 'تأكيد', false),
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            description,
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
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await cubit.savePlanDetails({
      'id': plan.id,
      'status': status,
      'reason': '$confirm الباقة من وحدة التحكم',
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

Color _planStatusColor(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
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

const Map<String, String> _planStatusLabels = {
  'active': 'نشطة',
  'draft': 'مسودات',
  'archived': 'مؤرشفة',
};

class _PlanGallery extends StatelessWidget {
  const _PlanGallery({
    required this.state,
    required this.tabBar,
    required this.query,
    required this.statusFilter,
    required this.onQuery,
    required this.onStatus,
    required this.onOpen,
    required this.onCreate,
    required this.onEdit,
    required this.onClone,
    required this.onStatusChange,
  });

  final PlatformLicensingLoaded state;
  final Widget? tabBar;
  final String query;
  final String? statusFilter;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String> onOpen;
  final VoidCallback onCreate;
  final ValueChanged<LicensingPlan> onEdit;
  final ValueChanged<LicensingPlan> onClone;
  final void Function(LicensingPlan plan, String status) onStatusChange;

  List<LicensingPlan> get _visible {
    final q = query.trim().toLowerCase();
    return _sortPlans(
      state.plans.where((plan) {
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
    final plans = state.plans;
    final visible = _visible;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _GalleryHeader(state: state, tabBar: tabBar, onCreate: onCreate),
        const SizedBox(height: AppSpacing.medium),
        LicensingToolbar(
          search: DebouncedSearchField(
            initialValue: query,
            hintText: 'ابحث باسم الباقة أو مفتاحها',
            onChanged: onQuery,
          ),
          filters: [
            FilterChip(
              label: Text('الكل (${plans.length})'),
              selected: statusFilter == null,
              onSelected: (_) => onStatus(null),
            ),
            for (final entry in _planStatusLabels.entries)
              if (plans.any((p) => p.status == entry.key))
                FilterChip(
                  label: Text(
                    '${entry.value} '
                    '(${plans.where((p) => p.status == entry.key).length})',
                  ),
                  selected: statusFilter == entry.key,
                  onSelected: (on) => onStatus(on ? entry.key : null),
                ),
          ],
          trailing: Text(
            visible.length == plans.length
                ? '${plans.length} باقة'
                : '${visible.length} من ${plans.length} باقة',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (visible.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: DashboardEmptyState(
              icon: DashboardIcons.plans,
              title: plans.isEmpty ? 'لا توجد باقات' : 'لا باقة تطابق البحث',
              message: plans.isEmpty
                  ? 'أنشئ باقة لتبدأ ترخيص المكاتب.'
                  : 'جرّب مصطلحًا آخر أو أزل عوامل التصفية.',
              action: plans.isEmpty
                  ? FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(DashboardIcons.add, size: 18),
                      label: const Text('باقة جديدة'),
                    )
                  : TextButton(
                      onPressed: () => onStatus(null),
                      child: const Text('عرض كل الباقات'),
                    ),
            ),
          )
        else
          LicensingCardGrid(
            minCardWidth: 340,
            maxColumns: 3,
            children: [
              for (final plan in visible)
                _PlanCard(
                  plan: plan,
                  onOpen: () => onOpen(plan.id),
                  onEdit: () => onEdit(plan),
                  onClone: () => onClone(plan),
                  onStatusChange: (status) => onStatusChange(plan, status),
                ),
            ],
          ),
      ],
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.state,
    required this.tabBar,
    required this.onCreate,
  });

  final PlatformLicensingLoaded state;
  final Widget? tabBar;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plans = state.plans;
    final active = plans.where((p) => p.status == 'active').length;
    final offices = plans.fold<int>(0, (sum, p) => sum + p.officeCount);

    final contracted = plans
        .where((p) => p.priceMonthly != null)
        .fold<num>(0, (sum, p) => sum + p.priceMonthly! * p.officeCount);
    final negotiated = plans
        .where((p) => p.priceMonthly == null)
        .fold<int>(0, (sum, p) => sum + p.officeCount);

    return LicensingConsoleHeader(
      icon: DashboardIcons.plans,
      title: 'الباقات والميزات',
      subtitle:
          'ما تبيعه المنصة للمكاتب. الباقة قالب بلا سلوك، ولهذا يمكن تعديلها '
          'وهي حيّة — والتعديل يسري فورًا على كل مكتب مشترك.',
      actions: [
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(DashboardIcons.add, size: 18),
          label: const Text('باقة جديدة'),
        ),
      ],
      tabBar: tabBar,
      stats: [
        LicensingStat(
          icon: DashboardIcons.plans,
          value: '${plans.length}',
          label: '$active نشطة',
        ),
        LicensingStat(
          icon: DashboardIcons.platformOffices,
          value: '$offices',
          label: 'مكتب مشترك',
          color: scheme.secondary,
        ),
        LicensingStat(
          icon: DashboardIcons.payments,
          value: licensingMoney(contracted),
          label: negotiated == 0
              ? 'إيراد شهري متعاقد'
              : 'متعاقد · عدا $negotiated بسعر تفاوضي',
        ),
        LicensingStat(
          icon: DashboardIcons.featureCatalog,
          value: '${state.catalog.features.length}',
          label: '${state.catalog.enforcedCount} مطبَّقة بكود',
          color: state.catalog.declaredCount > 0 ? scheme.tertiary : null,
        ),
      ],
    );
  }
}

/// One plan, the way a pricing page shows one.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onOpen,
    required this.onEdit,
    required this.onClone,
    required this.onStatusChange,
  });

  final LicensingPlan plan;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onClone;
  final ValueChanged<String> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _planStatusColor(context, plan.status);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.radius),
                topRight: Radius.circular(AppTokens.radius),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.nameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      if (plan.status != 'active')
                        DashboardStatusChip(
                          label: plan.statusLabelAr,
                          color: statusColor.withAlpha(24),
                          textColor: statusColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.taglineAr.trim().isEmpty
                        ? plan.key
                        : plan.taglineAr.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _PlanPrice(plan: plan),
                  const SizedBox(height: AppSpacing.medium),
                  Wrap(
                    spacing: AppSpacing.xSmall,
                    runSpacing: AppSpacing.xSmall,
                    children: [
                      LicensingFact(
                        icon: DashboardIcons.platformOffices,
                        label: plan.officeCount == 0
                            ? 'بلا مكاتب'
                            : '${plan.officeCount} مكتب',
                        color: plan.officeCount > 0 ? scheme.secondary : null,
                      ),
                      if (plan.trialDays > 0)
                        LicensingFact(
                          icon: DashboardIcons.time,
                          label: 'تجربة ${plan.trialDays} يوم',
                        ),
                      LicensingFact(
                        icon: plan.isPublic
                            ? Icons.storefront_outlined
                            : DashboardIcons.locked,
                        label: plan.isPublic ? 'معروضة' : 'بالتعيين فقط',
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.medium),
                  Divider(height: 1, color: DashboardColors.divider(context)),
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: onOpen,
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('تحرير الميزات'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xSmall),
                      IconButton(
                        tooltip: 'تعديل بيانات البيع',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'المزيد',
                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                        onSelected: (action) => action == 'clone'
                            ? onClone()
                            : onStatusChange(action),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'clone',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.copy_rounded),
                              title: Text('نسخ الباقة'),
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
            ),
          ),
        ],
      ),
    );
  }
}

/// The figure a plan is sold at, given the weight it has in the decision.
class _PlanPrice extends StatelessWidget {
  const _PlanPrice({required this.plan});

  final LicensingPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (plan.priceMonthly == null) {
      return Text(
        'سعر تفاوضي',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: DashboardColors.mutedInk(context),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            licensingMoney(plan.priceMonthly, plan.currency),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '/ شهر',
          style: theme.textTheme.bodySmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
        if (plan.priceYearly != null) ...[
          const SizedBox(width: AppSpacing.small),
          Text(
            '· ${licensingMoney(plan.priceYearly, plan.currency)} / سنة',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// One plan, full width.
///
/// The whole pane scrolls and the save bar floats over it. There is no fixed
/// header over a flexed body here on purpose: that shape is what clipped this
/// screen on a short console window, and a sticky action bar is the shape a web
/// app uses for exactly this job.
///
/// **The content sits in a centred lane rather than filling the console.** A
/// plan editor is a form, and a form row 1900px wide puts a feature's name
/// against one edge of the monitor and its switch against the other — so the
/// eye has to cross the whole screen to make the association the row exists to
/// make. The save bar rides the same lane, so it never floats free of the thing
/// it is saving.
class _PlanWorkspace extends StatelessWidget {
  const _PlanWorkspace({
    required this.state,
    required this.detail,
    required this.draft,
    required this.changedKeys,
    required this.note,
    required this.tab,
    required this.featureQuery,
    required this.featureCategory,
    required this.featureSearchEpoch,
    required this.view,
    required this.onTab,
    required this.onFeatureQuery,
    required this.onFeatureCategory,
    required this.onView,
    required this.onResetFilters,
    required this.onValueChanged,
    required this.onValueCleared,
    required this.onValuesCleared,
    required this.onSave,
    required this.onDiscard,
    required this.onBack,
    required this.onEdit,
    required this.onClone,
    required this.onStatusChange,
  });

  final PlatformLicensingLoaded state;
  final PlanDetail detail;
  final Map<String, Object?> draft;
  final Set<String> changedKeys;
  final TextEditingController note;
  final int tab;
  final String featureQuery;
  final String? featureCategory;
  final int featureSearchEpoch;
  final _FeatureView view;
  final ValueChanged<int> onTab;
  final ValueChanged<String> onFeatureQuery;
  final ValueChanged<String?> onFeatureCategory;
  final ValueChanged<_FeatureView> onView;
  final VoidCallback onResetFilters;
  final void Function(String key, Object? value) onValueChanged;
  final ValueChanged<String> onValueCleared;
  final ValueChanged<Iterable<String>> onValuesCleared;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onClone;
  final ValueChanged<String> onStatusChange;

  /// Wide enough for the editor's five lanes at full spread, narrow enough that
  /// a row's two ends stay in one glance.
  static const double _contentWidth = 1320;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final isDirty = changedKeys.isNotEmpty;
    final selectable = state.catalog.features
        .where((f) => f.status != 'hidden')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = math.max(
          0.0,
          (constraints.maxWidth - _contentWidth) / 2,
        );

        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                left: gutter,
                right: gutter,
                bottom: isDirty
                    ? (constraints.maxWidth < 720 ? 220.0 : 132.0)
                    : 0.0,
              ),
              children: [
                _WorkspaceHeader(
                  detail: detail,
                  setCount: draft.length,
                  catalogCount: selectable,
                  onBack: onBack,
                  onEdit: onEdit,
                  onClone: onClone,
                  onStatusChange: onStatusChange,
                  onPreview: () => cubit.previewPlan(detail.plan.id),
                ),
                const SizedBox(height: AppSpacing.medium),
                LicensingTabs(
                  selected: tab,
                  onChanged: onTab,
                  tabs: [
                    LicensingTab(
                      label: 'الميزات',
                      icon: DashboardIcons.featureCatalog,
                      count: detail.values.length,
                    ),
                    LicensingTab(
                      label: 'المكاتب',
                      icon: DashboardIcons.platformOffices,
                      count: detail.offices.length,
                    ),
                    LicensingTab(
                      label: 'السجل',
                      icon: DashboardIcons.audit,
                      count: detail.revisions.length,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                switch (tab) {
                  1 => _PlanOffices(detail: detail),
                  2 => _PlanRevisions(detail: detail, catalog: state.catalog),
                  _ => _FeatureEditor(
                    catalog: state.catalog,
                    draft: draft,
                    saved: detail.values,
                    changedKeys: changedKeys,
                    preview: state.planPreview,
                    query: featureQuery,
                    searchEpoch: featureSearchEpoch,
                    category: featureCategory,
                    view: view,
                    onQuery: onFeatureQuery,
                    onCategory: onFeatureCategory,
                    onView: onView,
                    onResetFilters: onResetFilters,
                    onChanged: onValueChanged,
                    onCleared: onValueCleared,
                    onClearedMany: onValuesCleared,
                    onClosePreview: cubit.clearPlanPreview,
                  ),
                },
              ],
            ),
            if (isDirty)
              Positioned(
                left: gutter,
                right: gutter,
                bottom: AppSpacing.medium,
                child: LicensingSaveBar(
                  changedCount: changedKeys.length,
                  noteController: note,
                  onDiscard: onDiscard,
                  onSave: onSave,
                  message:
                      'الحفظ يسري فورًا على ${detail.offices.length} مكتب مشترك، '
                      'وتُحفظ الحالة السابقة في السجل.',
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The open plan's identity, its commercial terms, and its actions.
///
/// This is where the operator confirms *which product they are editing*, so it
/// is built like a product header rather than a row of equal pills: a way out,
/// the plan's name and its pitch, then a vitals strip where the price carries
/// the weight a price has in the decision. The five bordered pills it replaced
/// said «1500 ج.م / شهر» and «بلا فترة تجريبية» in exactly the same voice,
/// which is a header that answers nothing at a glance.
class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.detail,
    required this.setCount,
    required this.catalogCount,
    required this.onBack,
    required this.onEdit,
    required this.onClone,
    required this.onStatusChange,
    required this.onPreview,
  });

  final PlanDetail detail;

  /// How many features the plan pins right now — read from the working copy,
  /// not the stored one, so the strip never disagrees with the list under it.
  final int setCount;

  final int catalogCount;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onClone;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plan = detail.plan;
    final statusColor = _planStatusColor(context, plan.status);
    final muted = DashboardColors.mutedInk(context);
    final tagline = plan.taglineAr.trim();

    // Breakpoints are widths in *unscaled* pixels, and the actions are three
    // Arabic buttons: at 1.6× they need half again as much room, and the
    // identity beside them gets squeezed past its 46px glyph. Scaling the
    // breakpoint is what makes the header stack when it actually has to.
    final stackBelow = MediaQuery.textScalerOf(context).scale(780);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(DashboardIcons.back, size: 18),
                label: const Text('كل الباقات'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  '${plan.key} · المراجعة رقم ${plan.revision}',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          LayoutBuilder(
            builder: (context, constraints) {
              final identity = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(22),
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusSmall,
                      ),
                      border: Border.all(color: statusColor.withAlpha(60)),
                    ),
                    child: Icon(DashboardIcons.plansActive, color: statusColor),
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
                            DashboardStatusChip(
                              label: plan.statusLabelAr,
                              color: statusColor.withAlpha(24),
                              textColor: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tagline.isEmpty
                              ? 'بلا وصف تجاري — أضِفه من «بيانات البيع» ليقرأه '
                                    'المكتب قبل الاشتراك.'
                              : tagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            height: 1.5,
                            fontStyle: tagline.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actions = Wrap(
                spacing: AppSpacing.xSmall,
                runSpacing: AppSpacing.xSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // A draft sells nothing until it is published, so that one
                  // action never hides under «⋯».
                  if (plan.status == 'draft')
                    FilledButton.icon(
                      onPressed: () => onStatusChange('active'),
                      icon: const Icon(Icons.publish_rounded, size: 18),
                      label: const Text('نشر الباقة'),
                    ),
                  OutlinedButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('معاينة الصلاحيات'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('بيانات البيع'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'إجراءات الباقة',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (action) =>
                        action == 'clone' ? onClone() : onStatusChange(action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'clone',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.copy_rounded),
                          title: Text('نسخ الباقة'),
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
              );

              if (constraints.maxWidth < stackBelow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: AppSpacing.medium),
                    actions,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: AppSpacing.medium),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: DashboardColors.well(context),
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: DashboardColors.border(context)),
            ),
            child: LicensingStatStrip(
              spread: true,
              stats: [
                LicensingStat(
                  icon: DashboardIcons.payments,
                  value: plan.priceMonthly == null
                      ? 'سعر تفاوضي'
                      : licensingMoney(plan.priceMonthly, plan.currency),
                  label: plan.priceMonthly == null
                      ? 'يُتفق عليه مع كل مكتب'
                      : plan.priceYearly == null
                      ? 'شهريًا'
                      : 'شهريًا · '
                            '${licensingMoney(plan.priceYearly, plan.currency)} سنويًا',
                ),
                LicensingStat(
                  icon: DashboardIcons.platformOffices,
                  value: '${plan.officeCount}',
                  label: plan.officeCount == 0
                      ? 'لا مكتب على هذه الباقة'
                      : 'مكتب مشترك — التعديل يسري عليه فورًا',
                  color: plan.officeCount > 0 ? scheme.secondary : null,
                ),
                LicensingStat(
                  icon: DashboardIcons.featureCatalog,
                  value: '$setCount من $catalogCount',
                  label: 'ميزة تضبطها الباقة · الباقي يتبع الكتالوج',
                ),
                LicensingStat(
                  icon: DashboardIcons.time,
                  value: plan.trialDays > 0 ? '${plan.trialDays} يوم' : 'بلا',
                  label: 'فترة تجريبية',
                ),
                LicensingStat(
                  icon: plan.isPublic
                      ? Icons.storefront_outlined
                      : DashboardIcons.locked,
                  value: plan.isPublic ? 'معروضة' : 'بالتعيين فقط',
                  label: plan.isPublic
                      ? 'يراها المكتب عند الاشتراك'
                      : 'تُسند يدويًا من التراخيص',
                ),
              ],
            ),
          ),
          if (plan.isArchived) ...[
            const SizedBox(height: AppSpacing.medium),
            LicensingNotice(
              icon: Icons.archive_outlined,
              color: scheme.error,

              message:
                  'باقة مؤرشفة — المكاتب المشتركة تعمل كما هي، ولا يمكن '
                  'تعيينها لمكتب جديد.',
            ),
          ],
        ],
      ),
    );
  }
}

/// Which slice of the catalog the plan editor is showing.
///
/// The control this replaced was a single «المضبوطة في الباقة» chip sitting in
/// the same wrap as eight category chips — two unrelated axes in identical
/// clothes, and only a *half* answer to the question a plan is opened with:
/// what does it override, and what does it inherit? Both halves are now places
/// you can go, and the complement of one is the other.
enum _FeatureView {
  all('الكل'),
  setHere('المضبوطة في الباقة'),
  inherited('تتبع الافتراضي'),
  changed('غير محفوظة');

  const _FeatureView(this.labelAr);

  final String labelAr;
}

class _FeatureEditor extends StatelessWidget {
  const _FeatureEditor({
    required this.catalog,
    required this.draft,
    required this.saved,
    required this.changedKeys,
    required this.query,
    required this.searchEpoch,
    required this.category,
    required this.view,
    required this.onQuery,
    required this.onCategory,
    required this.onView,
    required this.onResetFilters,
    required this.onChanged,
    required this.onCleared,
    required this.onClearedMany,
    required this.onClosePreview,
    this.preview,
  });

  final FeatureCatalog catalog;
  final Map<String, Object?> draft;
  final Map<String, Object?> saved;
  final Set<String> changedKeys;
  final String query;

  /// Bumped by the section when it clears the filters, so the search field is
  /// rebuilt around an empty controller. Keying it on "is the query empty"
  /// instead would tear the field down on the first character typed and take
  /// the focus with it.
  final int searchEpoch;

  final String? category;
  final _FeatureView view;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onCategory;
  final ValueChanged<_FeatureView> onView;
  final VoidCallback onResetFilters;
  final Map<String, dynamic>? preview;
  final void Function(String key, Object? value) onChanged;
  final ValueChanged<String> onCleared;
  final ValueChanged<Iterable<String>> onClearedMany;
  final VoidCallback onClosePreview;

  bool _matches(CatalogFeature feature, _FeatureView activeView) {
    if (feature.status == 'hidden') return false;
    if (category != null && feature.categoryKey != category) return false;

    final inView = switch (activeView) {
      _FeatureView.all => true,
      _FeatureView.setHere => draft.containsKey(feature.key),
      _FeatureView.inherited => !draft.containsKey(feature.key),
      _FeatureView.changed => changedKeys.contains(feature.key),
    };
    if (!inView) return false;

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return feature.nameAr.contains(q) ||
        feature.key.toLowerCase().contains(q) ||
        feature.nameEn.toLowerCase().contains(q) ||
        feature.descriptionAr.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final selectable = catalog.features
        .where((f) => f.status != 'hidden')
        .toList();

    // Discarding empties `changedKeys` while «غير محفوظة» is the open view, and
    // a `SegmentedButton` whose selection is not among its segments asserts.
    final activeView = view == _FeatureView.changed && changedKeys.isEmpty
        ? _FeatureView.all
        : view;

    final setCount = selectable.where((f) => draft.containsKey(f.key)).length;
    final visible = selectable.where((f) => _matches(f, activeView)).toList();

    final grouped = <String, List<CatalogFeature>>{};
    for (final feature in visible) {
      grouped.putIfAbsent(feature.categoryKey, () => []).add(feature);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    final orderedKeys = [
      for (final c in catalog.categories)
        if (grouped.containsKey(c.key)) c.key,
      ...grouped.keys.where(
        (key) => !catalog.categories.any((c) => c.key == key),
      ),
    ];

    final categoryCounts = <String, int>{};
    for (final feature in selectable) {
      categoryCounts.update(
        feature.categoryKey,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }

    final activeFilters = <String>[
      if (query.trim().isNotEmpty) 'بحث: «${query.trim()}»',
      if (category != null) 'التصنيف: ${catalog.categoryName(category!)}',
      if (activeView != _FeatureView.all) activeView.labelAr,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (preview != null) ...[
          _PreviewPanel(preview: preview!, onClose: onClosePreview),
          const SizedBox(height: AppSpacing.medium),
        ],
        LicensingToolbar(
          searchWidth: 320,
          search: DebouncedSearchField(
            key: ValueKey('plan-feature-search-$searchEpoch'),
            initialValue: query,
            hintText: 'ابحث بالاسم أو المفتاح أو الوصف',
            onChanged: onQuery,
          ),
          filters: [
            SegmentedButton<_FeatureView>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              segments: [
                ButtonSegment(
                  value: _FeatureView.all,
                  label: Text('الكل (${selectable.length})'),
                ),
                ButtonSegment(
                  value: _FeatureView.setHere,
                  label: Text('المضبوطة في الباقة ($setCount)'),
                ),
                ButtonSegment(
                  value: _FeatureView.inherited,
                  label: Text(
                    'تتبع الافتراضي (${selectable.length - setCount})',
                  ),
                ),
                if (changedKeys.isNotEmpty)
                  ButtonSegment(
                    value: _FeatureView.changed,
                    label: Text('غير محفوظة (${changedKeys.length})'),
                  ),
              ],
              selected: {activeView},
              onSelectionChanged: (selection) => onView(selection.first),
            ),
            LicensingFilterDropdown(
              label: 'التصنيف',
              value: category == null
                  ? 'الكل'
                  : catalog.categoryName(category!),
              isActive: category != null,
              options: [
                (value: null, label: 'الكل (${selectable.length})'),
                for (final c in catalog.categories)
                  if ((categoryCounts[c.key] ?? 0) > 0)
                    (
                      value: c.key,
                      label: '${c.nameAr} (${categoryCounts[c.key]})',
                    ),
              ],
              onSelected: onCategory,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        LicensingResultsBar(
          summary: 'يُعرض ${visible.length} من ${selectable.length}',
          activeFilters: activeFilters,
          onReset: activeFilters.isEmpty ? null : onResetFilters,
          note:
              'ميزة بلا قيمة في الباقة ترجع إلى الافتراضي المسجَّل في الكتالوج — '
              'وهذا ليس نفس معنى «مُعطَّلة».',
        ),
        const SizedBox(height: AppSpacing.medium),
        if (visible.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: DashboardEmptyState(
              icon: DashboardIcons.featureCatalog,
              title: switch (activeView) {
                _FeatureView.setHere => 'لا قيمة مضبوطة في هذه الباقة',
                _FeatureView.inherited => 'الباقة تضبط كل ميزة في الكتالوج',
                _FeatureView.changed => 'لا تعديل غير محفوظ',
                _FeatureView.all => 'لا ميزة تطابق البحث',
              },
              message: switch (activeView) {
                _FeatureView.setHere =>
                  'الباقة تتبع الكتالوج بالكامل — كل ميزة على قيمتها الافتراضية.',
                _FeatureView.inherited =>
                  'لا ميزة متروكة للافتراضي هنا؛ كل شيء منصوص عليه في الباقة.',
                _FeatureView.changed => 'كل ما عدّلته محفوظ بالفعل.',
                _FeatureView.all => 'جرّب اسمًا آخر أو مفتاح الميزة.',
              },
              action: TextButton(
                onPressed: onResetFilters,
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
                    name: catalog.categoryName(key),
                    features: grouped[key]!,
                    draft: draft,
                    saved: saved,
                    changedKeys: changedKeys,
                    onChanged: onChanged,
                    onCleared: onCleared,
                    onClearedMany: onClearedMany,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A category heading and its rows, in the same card as its neighbours.
///
/// Not a collapsible section: a plan is edited by sweeping the whole catalog,
/// and a column of folded headers turns "set the limits" into fifteen clicks
/// before the first one.
///
/// The heading earns its own action instead. Sweeping a category and deciding
/// «this whole group should just follow the catalog» used to be one click per
/// row with no way to see how many rows that was.
class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.name,
    required this.features,
    required this.draft,
    required this.saved,
    required this.changedKeys,
    required this.onChanged,
    required this.onCleared,
    required this.onClearedMany,
  });

  final String name;
  final List<CatalogFeature> features;
  final Map<String, Object?> draft;
  final Map<String, Object?> saved;
  final Set<String> changedKeys;
  final void Function(String key, Object? value) onChanged;
  final ValueChanged<String> onCleared;
  final ValueChanged<Iterable<String>> onClearedMany;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final setHere = features.where((f) => draft.containsKey(f.key)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.medium,
            end: AppSpacing.small,
            top: AppSpacing.small,
            bottom: AppSpacing.small,
          ),
          decoration: BoxDecoration(
            color: DashboardColors.well(context),
            border: Border(
              top: BorderSide(color: DashboardColors.border(context)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      '${features.length} ميزة',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                      ),
                    ),
                    if (setHere.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.small),
                      DashboardStatusChip(
                        label: '${setHere.length} مضبوطة',
                        color: scheme.primary.withAlpha(20),
                        textColor: scheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
              if (setHere.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      onClearedMany(setHere.map((f) => f.key).toList()),
                  icon: const Icon(
                    Icons.settings_backup_restore_rounded,
                    size: 16,
                  ),
                  label: const Text('إرجاع الكل للافتراضي'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: DashboardColors.mutedInk(context),
                  ),
                ),
            ],
          ),
        ),
        for (final feature in features)
          _FeatureEditRow(
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
    );
  }
}

/// One feature, and the control that sets it.
///
/// **The row is lanes, not two ends.** It used to be a name, an `Expanded` gap
/// and a control — so on a console monitor the label sat against one edge of
/// the screen and its switch against the other, with a hand-span of nothing in
/// between, and associating the two was the only thing the row was for. The gap
/// is now the two facts the operator needed anyway: what the feature *does*,
/// and where its current value comes from. A hover tint tracks the row across
/// the width on top of that.
///
/// **The state rail says which of three things this row is** — untouched, set
/// by the plan, or edited and not yet saved — in the peripheral vision, at the
/// start edge, before any text is read.
class _FeatureEditRow extends StatefulWidget {
  const _FeatureEditRow({
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

  /// What is stored for this key right now, when anything is — surfaced only
  /// while the row is dirty, so "what am I about to change it from?" is
  /// answerable without leaving the screen.
  final String? savedLabel;

  final ValueChanged<Object?> onChanged;
  final VoidCallback onCleared;

  @override
  State<_FeatureEditRow> createState() => _FeatureEditRowState();
}

class _FeatureEditRowState extends State<_FeatureEditRow> {
  bool _hovered = false;

  /// The middle lane: what this feature actually does, in the operator's words
  /// where the catalog has them and in the system's where it does not. Never
  /// invented — an empty lane is more honest than a restated name.
  String _context() {
    final feature = widget.feature;
    if (feature.descriptionAr.trim().isNotEmpty) {
      return feature.descriptionAr.trim();
    }
    if (!feature.isEnforced) {
      return 'مُدرجة في الكتالوج ولا يوجد كود يطبّقها بعد.';
    }
    if (feature.gates.isNotEmpty) {
      final kinds = feature.gates.map((g) => g.kindLabelAr).toSet();
      return 'تُطبَّق عبر ${kinds.join(' و')}.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final feature = widget.feature;
    final muted = DashboardColors.mutedInk(context);

    final railColor = widget.isChanged
        ? scheme.tertiary
        : (widget.isSet ? scheme.primary : Colors.transparent);

    final background = widget.isChanged
        ? scheme.tertiary.withAlpha(14)
        : (_hovered ? DashboardColors.tableRowHover(context) : null);

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              feature.nameAr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!feature.isEnforced) const EnforcementBadge(isEnforced: false),
            if (feature.isKillSwitched)
              DashboardStatusChip(
                label: 'موقوفة على مستوى المنصة',
                color: scheme.error.withAlpha(24),
                textColor: scheme.error,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          feature.key,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: muted),
        ),
      ],
    );

    final origin = Wrap(
      spacing: AppSpacing.xSmall,
      runSpacing: 4,
      children: [
        if (widget.isSet)
          DashboardStatusChip(
            label: 'مضبوطة في الباقة',
            color: scheme.primary.withAlpha(20),
            textColor: scheme.primary,
          )
        else
          DashboardStatusChip(
            label:
                'الافتراضي · '
                '${FeatureValue.label(feature.defaultValue, unit: feature.unitAr)}',
            color: DashboardColors.well(context),
            textColor: muted,
          ),
        if (widget.isChanged)
          DashboardStatusChip(
            label: widget.savedLabel == null
                ? 'جديدة · لم تُحفظ'
                : 'كانت: ${widget.savedLabel}',
            color: scheme.tertiary.withAlpha(22),
            textColor: scheme.tertiary,
          ),
      ],
    );

    final control = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FeatureValueField(
          feature: feature,
          value: widget.value,
          onChanged: widget.onChanged,
        ),
        // A permanently greyed icon on every one of forty-seven rows is noise;
        // the lane still holds its width so the controls stay in one column.
        if (widget.isSet)
          IconButton(
            tooltip: 'إرجاع إلى الافتراضي',
            icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
            onPressed: widget.onCleared,
          )
        else
          const SizedBox(width: 40),
      ],
    );

    final description = _context();
    final scaler = MediaQuery.textScalerOf(context);
    final stackBelow = scaler.scale(700);
    final describeAbove = scaler.scale(1000);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(
            top: BorderSide(color: DashboardColors.divider(context)),
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: railColor),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.medium,
                end: AppSpacing.small,
                top: AppSpacing.small,
                bottom: AppSpacing.small,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < stackBelow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        identity,
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.small),
                        Row(
                          children: [
                            Expanded(child: origin),
                            const SizedBox(width: AppSpacing.small),
                            control,
                          ],
                        ),
                      ],
                    );
                  }

                  final showDescription = constraints.maxWidth >= describeAbove;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 5, child: identity),
                      if (showDescription) ...[
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          flex: 4,
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.medium),
                      // minWidth, never a fixed width: one Arabic chip wider
                      // than the lane and it clips.
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 160),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: origin,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 250),
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: control,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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

class _PlanOffices extends StatelessWidget {
  const _PlanOffices({required this.detail});

  final PlanDetail detail;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
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
          : LicensingCardGrid(
              minCardWidth: 300,
              spacing: AppSpacing.small,
              children: [
                for (final office in detail.offices)
                  Container(
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
              ],
            ),
    );
  }
}

class _PlanRevisions extends StatelessWidget {
  const _PlanRevisions({required this.detail, required this.catalog});

  final PlanDetail detail;
  final FeatureCatalog catalog;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      icon: DashboardIcons.audit,
      title: 'السجل',
      subtitle: 'تُحفظ نسخة تلقائيًا قبل كل تعديل، وتُقارَن بالحالة الحالية.',
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
                    child: _RevisionDiff(changes: _changes(revision.features)),
                  ),
              ],
            ),
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
