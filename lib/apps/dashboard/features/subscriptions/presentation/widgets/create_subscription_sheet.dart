import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/user_subscription.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import 'subscription_formatting.dart';

/// Opens the manual subscription form as a modal sheet.
///
/// A sheet rather than a pushed route: creating a subscription is a short form
/// the operator returns from immediately, and the list behind it stays in view.
Future<void> openCreateSubscription(
  BuildContext context,
  SubscriptionsLoaded state,
) {
  final cubit = context.read<SubscriptionsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 720),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTokens.radiusSheet),
      ),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: CreateSubscriptionSheet(options: state.creationOptions),
    ),
  );
}

class CreateSubscriptionSheet extends StatefulWidget {
  const CreateSubscriptionSheet({super.key, required this.options});

  final SubscriptionCreationOptions options;

  @override
  State<CreateSubscriptionSheet> createState() =>
      _CreateSubscriptionSheetState();
}

class _CreateSubscriptionSheetState extends State<CreateSubscriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  SubscriptionUserOption? _user;
  SubscriptionPlanOption? _plan;
  SubscriptionRouteOption? _route;
  DateTime? _startDate;

  /// End date is derived from the plan's day count, never typed: the database
  /// derives it the same way on renewal, and two sources would drift.
  DateTime? get _endDate {
    final plan = _plan;
    final start = _startDate;
    if (plan == null || start == null) return null;
    return DateTime(start.year, start.month, start.day + plan.days - 1);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<SubscriptionsCubit, SubscriptionsState>(
      listenWhen: (previous, current) =>
          current is SubscriptionsLoaded && current.actionMessage != null,
      listener: (context, state) => Navigator.of(context).maybePop(),
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.large,
              0,
              AppSpacing.large,
              AppSpacing.large,
            ),
            children: [
              Text(
                'اشتراك جديد',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'اختر العميل والباقة وخط السير وتاريخ البداية. يُنشأ الاشتراك '
                'بحالة "بانتظار الدفع".',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              _Dropdown<SubscriptionUserOption>(
                label: 'العميل',
                icon: Icons.person_outline_rounded,
                value: _user,
                items: options.users,
                itemLabel: (user) =>
                    '${user.name}${user.phone.isEmpty ? '' : ' — ${arabicDigits(user.phone)}'}',
                emptyHint: 'لا يوجد عملاء مسجلون',
                onChanged: (value) => setState(() => _user = value),
              ),
              const SizedBox(height: AppSpacing.medium),
              _Dropdown<SubscriptionPlanOption>(
                label: 'الباقة',
                icon: Icons.inventory_2_outlined,
                value: _plan,
                items: options.plans,
                itemLabel: (plan) =>
                    '${plan.name} — ${subscriptionMoney(plan.price)}',
                emptyHint: 'لا توجد باقات — أنشئ باقة أولاً',
                onChanged: (value) => setState(() => _plan = value),
              ),
              const SizedBox(height: AppSpacing.medium),
              _Dropdown<SubscriptionRouteOption>(
                label: 'خط السير',
                icon: Icons.alt_route_rounded,
                value: _route,
                items: options.routes,
                itemLabel: (route) => route.label,
                emptyHint: 'لا توجد خطوط سير في هذا المكتب',
                onChanged: (value) => setState(() => _route = value),
              ),
              const SizedBox(height: AppSpacing.medium),
              _StartDateField(
                value: _startDate,
                onPick: (value) => setState(() => _startDate = value),
              ),
              const SizedBox(height: AppSpacing.large),
              _Summary(plan: _plan, endDate: _endDate),
              const SizedBox(height: AppSpacing.large),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('إنشاء الاشتراك'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    if (_user == null ||
        _plan == null ||
        _route == null ||
        _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل بيانات الاشتراك المطلوبة')),
      );
      return;
    }
    context.read<SubscriptionsCubit>().createManualSubscription(
      user: _user!,
      plan: _plan!,
      route: _route!,
      startDate: _startDate!,
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.emptyHint,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final String emptyHint;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          enabled: false,
        ),
        child: Text(
          emptyHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'مطلوب' : null,
    );
  }
}

class _StartDateField extends StatelessWidget {
  const _StartDateField({required this.value, required this.onPick});

  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ البداية',
          prefixIcon: Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          value == null ? 'اختر التاريخ' : subscriptionDate(value!),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: value == null ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      helpText: 'تاريخ بداية الاشتراك',
    );
    if (selected != null) onPick(selected);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.plan, required this.endDate});

  final SubscriptionPlanOption? plan;
  final DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.primary.withAlpha(45)),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'قيمة الاشتراك',
            value: plan == null ? '—' : subscriptionMoney(plan!.price),
          ),
          const SizedBox(height: AppSpacing.small),
          _SummaryRow(
            label: 'رصيد الرحلات',
            value: plan == null
                ? '—'
                : plan!.tripsCount == 0
                ? 'باقة بالمدة'
                : '${arabicNumber(plan!.tripsCount)} رحلة',
          ),
          const SizedBox(height: AppSpacing.small),
          _SummaryRow(
            label: 'تاريخ النهاية المحسوب',
            value: endDate == null ? '—' : subscriptionDate(endDate!),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
