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
  bool _modifiedOnly = false;

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
      modifiedOnly: _modifiedOnly,
      onTab: (i) => setState(() => _tab = i),
      onFeatureQuery: (q) => setState(() => _featureQuery = q),
      onFeatureCategory: (c) => setState(() => _featureCategory = c),
      onModifiedOnly: (v) => setState(() => _modifiedOnly = v),
      onValueChanged: (key, value) => setState(() => _draft[key] = value),
      onValueCleared: (key) => setState(() => _draft.remove(key)),
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
      _modifiedOnly = false;
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
                        StatusChip(
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
    required this.modifiedOnly,
    required this.onTab,
    required this.onFeatureQuery,
    required this.onFeatureCategory,
    required this.onModifiedOnly,
    required this.onValueChanged,
    required this.onValueCleared,
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
  final bool modifiedOnly;
  final ValueChanged<int> onTab;
  final ValueChanged<String> onFeatureQuery;
  final ValueChanged<String?> onFeatureCategory;
  final ValueChanged<bool> onModifiedOnly;
  final void Function(String key, Object? value) onValueChanged;
  final ValueChanged<String> onValueCleared;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onClone;
  final ValueChanged<String> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final isDirty = changedKeys.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom: isDirty
                  ? (constraints.maxWidth < 720 ? 220.0 : 132.0)
                  : 0.0,
            ),
            children: [
              _WorkspaceHeader(
                detail: detail,
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
                  category: featureCategory,
                  modifiedOnly: modifiedOnly,
                  onQuery: onFeatureQuery,
                  onCategory: onFeatureCategory,
                  onModifiedOnly: onModifiedOnly,
                  onChanged: onValueChanged,
                  onCleared: onValueCleared,
                  onClosePreview: cubit.clearPlanPreview,
                ),
              },
            ],
          ),
          if (isDirty)
            Positioned(
              left: 0,
              right: 0,
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
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.detail,
    required this.onBack,
    required this.onEdit,
    required this.onClone,
    required this.onStatusChange,
    required this.onPreview,
  });

  final PlanDetail detail;
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

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(DashboardIcons.back, size: 18),
            label: const Text('كل الباقات'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
          const SizedBox(height: AppSpacing.small),
          LayoutBuilder(
            builder: (context, constraints) {
              final identity = Row(
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
                ],
              );

              final actions = Wrap(
                spacing: AppSpacing.xSmall,
                runSpacing: AppSpacing.xSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
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
              );

              if (constraints.maxWidth < 720) {
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
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [
              LicensingFact(
                icon: DashboardIcons.payments,
                label: plan.priceMonthly == null
                    ? 'سعر تفاوضي'
                    : '${licensingMoney(plan.priceMonthly, plan.currency)} / شهر',
              ),
              if (plan.priceYearly != null)
                LicensingFact(
                  icon: DashboardIcons.billing,
                  label:
                      '${licensingMoney(plan.priceYearly, plan.currency)} / سنة',
                ),
              LicensingFact(
                icon: DashboardIcons.time,
                label: plan.trialDays > 0
                    ? 'تجربة ${plan.trialDays} يوم'
                    : 'بلا فترة تجريبية',
              ),
              LicensingFact(
                icon: DashboardIcons.platformOffices,
                label: plan.officeCount == 0
                    ? 'لا مكتب على هذه الباقة'
                    : '${plan.officeCount} مكتب مشترك',
                color: plan.officeCount > 0 ? scheme.secondary : null,
              ),
              LicensingFact(
                icon: plan.isPublic
                    ? Icons.storefront_outlined
                    : DashboardIcons.locked,
                label: plan.isPublic ? 'معروضة للمكاتب' : 'بالتعيين فقط',
              ),
            ],
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

class _FeatureEditor extends StatelessWidget {
  const _FeatureEditor({
    required this.catalog,
    required this.draft,
    required this.saved,
    required this.changedKeys,
    required this.query,
    required this.category,
    required this.modifiedOnly,
    required this.onQuery,
    required this.onCategory,
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
  final String? category;
  final bool modifiedOnly;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onCategory;
  final ValueChanged<bool> onModifiedOnly;
  final Map<String, dynamic>? preview;
  final void Function(String key, Object? value) onChanged;
  final ValueChanged<String> onCleared;
  final VoidCallback onClosePreview;

  bool _matches(CatalogFeature feature) {
    if (feature.status == 'hidden') return false;
    if (category != null && feature.categoryKey != category) return false;
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
    final selectable = catalog.features
        .where((f) => f.status != 'hidden')
        .toList();
    final visible = catalog.features.where(_matches).toList();

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (preview != null) ...[
          _PreviewPanel(preview: preview!, onClose: onClosePreview),
          const SizedBox(height: AppSpacing.medium),
        ],
        LicensingToolbar(
          search: DebouncedSearchField(
            initialValue: query,
            hintText: 'ابحث في الميزات',
            onChanged: onQuery,
          ),
          filters: [
            FilterChip(
              label: Text('كل التصنيفات (${selectable.length})'),
              selected: category == null,
              onSelected: (_) => onCategory(null),
            ),
            for (final c in catalog.categories)
              if ((categoryCounts[c.key] ?? 0) > 0)
                FilterChip(
                  label: Text('${c.nameAr} (${categoryCounts[c.key]})'),
                  selected: category == c.key,
                  onSelected: (on) => onCategory(on ? c.key : null),
                ),
            FilterChip(
              avatar: const Icon(Icons.tune_rounded, size: 16),
              label: Text('المضبوطة في الباقة (${draft.length})'),
              selected: modifiedOnly,
              onSelected: onModifiedOnly,
            ),
          ],
          trailing: Text(
            'يُعرض ${visible.length} من ${selectable.length}',
            style: text.labelMedium?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (visible.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: DashboardEmptyState(
              icon: DashboardIcons.featureCatalog,
              title: modifiedOnly
                  ? 'لا قيمة مضبوطة في هذه الباقة'
                  : 'لا ميزة تطابق البحث',
              message: modifiedOnly
                  ? 'الباقة تتبع الكتالوج بالكامل — كل ميزة على قيمتها الافتراضية.'
                  : 'جرّب اسمًا آخر أو مفتاح الميزة.',
              action: TextButton(
                onPressed: () {
                  onModifiedOnly(false);
                  onCategory(null);
                  onQuery('');
                },
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
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.small),
        Text(
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

/// A category heading and its rows, in the same card as its neighbours.
///
/// Not a collapsible section: a plan is edited by sweeping the whole catalog,
/// and a column of folded headers turns "set the limits" into fifteen clicks
/// before the first one.
class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.name,
    required this.features,
    required this.draft,
    required this.saved,
    required this.changedKeys,
    required this.onChanged,
    required this.onCleared,
  });

  final String name;
  final List<CatalogFeature> features;
  final Map<String, Object?> draft;
  final Map<String, Object?> saved;
  final Set<String> changedKeys;
  final void Function(String key, Object? value) onChanged;
  final ValueChanged<String> onCleared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final setHere = features.where((f) => draft.containsKey(f.key)).length;

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
                setHere == 0
                    ? '${features.length} ميزة'
                    : '${features.length} ميزة · $setHere مضبوطة',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
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

class _FeatureEditRow extends StatelessWidget {
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: isChanged ? scheme.tertiary.withAlpha(14) : null,
        border: Border(
          top: BorderSide(color: DashboardColors.divider(context)),
        ),
      ),
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
                            '(${FeatureValue.label(feature.defaultValue, unit: feature.unitAr)}) · '
                            '${feature.key}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
