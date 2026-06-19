import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/user_subscription.dart';
import '../../plans/presentation/cubit/subscription_plans_cubit.dart';
import '../../plans/presentation/screens/subscription_plans_screen.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../widgets/subscriptions_analytics.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionsCubit, SubscriptionsState>(
      listener: (context, state) {
        if (state is SubscriptionsActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return switch (state) {
          SubscriptionsInitial() ||
          SubscriptionsLoading() => const DashboardLoading(),
          SubscriptionsError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<SubscriptionsCubit>().load(),
          ),
          SubscriptionsLoaded() => _SubscriptionsListView(
            state: state,
            onCreate: () => _openCreate(context),
          ),
          SubscriptionsActionSuccess() => _SubscriptionsListView(
            state: SubscriptionsLoaded(
              subscriptions: state.subscriptions,
              creationOptions: state.creationOptions,
            ),
            onCreate: () => _openCreate(context),
          ),
          SubscriptionDetailsLoaded() => SubscriptionDetailsScreen(
            subscription: state.subscription,
          ),
        };
      },
    );
  }

  void _openCreate(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();
    final state = cubit.state;
    final options = switch (state) {
      SubscriptionsLoaded(:final creationOptions) => creationOptions,
      SubscriptionsActionSuccess(:final creationOptions) => creationOptions,
      SubscriptionDetailsLoaded(:final creationOptions) => creationOptions,
      _ => null,
    };
    if (options == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: CreateSubscriptionScreen(options: options),
        ),
      ),
    );
  }
}

void openPlansManagement(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => dashboardDi<SubscriptionPlansCubit>()..load(),
        child: const Scaffold(body: SubscriptionPlansScreen()),
      ),
    ),
  );
}

class _SubscriptionsListView extends StatelessWidget {
  final SubscriptionsLoaded state;
  final VoidCallback onCreate;

  const _SubscriptionsListView({required this.state, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: Icons.workspace_premium_outlined,
          title: 'الاشتراكات',
          subtitle: 'تابع المشتركين والإيرادات وأدر باقات الاشتراك.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => openPlansManagement(context),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('إدارة الباقات'),
            ),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('اشتراك جديد'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        SubscriptionsAnalytics(subscriptions: state.subscriptions),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'قائمة المشتركين',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${_toArabicNumber(state.filteredSubscriptions.length)} اشتراك',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                onChanged: cubit.updateSearch,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'ابحث باسم العميل أو رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  _FilterChip(
                    label: 'الكل',
                    selected: state.statusFilter == null,
                    onTap: () => cubit.updateStatusFilter(null),
                  ),
                  _FilterChip(
                    label: 'نشط',
                    selected: state.statusFilter == SubscriptionStatus.active,
                    onTap: () =>
                        cubit.updateStatusFilter(SubscriptionStatus.active),
                  ),
                  _FilterChip(
                    label: 'بانتظار الدفع',
                    selected:
                        state.statusFilter == SubscriptionStatus.pendingPayment,
                    onTap: () => cubit.updateStatusFilter(
                      SubscriptionStatus.pendingPayment,
                    ),
                  ),
                  _FilterChip(
                    label: 'منتهي',
                    selected: state.statusFilter == SubscriptionStatus.expired,
                    onTap: () =>
                        cubit.updateStatusFilter(SubscriptionStatus.expired),
                  ),
                  _FilterChip(
                    label: 'ملغي',
                    selected:
                        state.statusFilter == SubscriptionStatus.cancelled,
                    onTap: () =>
                        cubit.updateStatusFilter(SubscriptionStatus.cancelled),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (state.filteredSubscriptions.isEmpty)
          const AppCard(child: Center(child: Text('لا توجد اشتراكات مطابقة.')))
        else
          ...state.filteredSubscriptions.map(
            (subscription) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: _SubscriptionCard(subscription: subscription),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final UserSubscription subscription;

  const _SubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.userName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(subscription.userPhone),
                  ],
                ),
              ),
              _SubscriptionStatusChip(status: subscription.status),
            ],
          ),
          const Divider(height: AppSpacing.large),
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.small,
            children: [
              _Info(label: 'الباقة', value: subscription.routeName),
              _Info(label: 'السعر', value: _money(subscription)),
              _Info(
                label: 'المدفوع',
                value: _amount(subscription.paidAmount),
              ),
              _Info(
                label: 'المتبقي',
                value: _amount(subscription.remainingAmount),
              ),
              _Info(
                label: 'الأيام المتبقية',
                value: '${_toArabicNumber(subscription.remainingDays)} يوم',
              ),
              _Info(
                label: 'المدة',
                value:
                    '${_date(subscription.startDate)} / ${_date(subscription.endDate)}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<SubscriptionsCubit>().loadDetails(subscription.id);
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('عرض التفاصيل'),
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionDetailsScreen extends StatelessWidget {
  final UserSubscription subscription;

  const SubscriptionDetailsScreen({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: context.read<SubscriptionsCubit>().showList,
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'رجوع',
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              'تفاصيل الاشتراك',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('بيانات العميل'),
              _DetailsGrid(
                items: [
                  _InfoData('العميل', subscription.userName),
                  _InfoData('الهاتف', subscription.userPhone),
                ],
              ),
              const Divider(height: AppSpacing.large),
              _SectionTitle('بيانات الاشتراك'),
              _DetailsGrid(
                items: [
                  _InfoData('الباقة', subscription.routeName),
                  _InfoData('السعر', _money(subscription)),
                  _InfoData('المدفوع', _amount(subscription.paidAmount)),
                  _InfoData('المتبقي', _amount(subscription.remainingAmount)),
                  _InfoData(
                    'عدد التجديدات',
                    _toArabicNumber(subscription.renewalsCount),
                  ),
                  _InfoData(
                    'الأيام المتبقية',
                    '${_toArabicNumber(subscription.remainingDays)} يوم',
                  ),
                  _InfoData('تاريخ البداية', _date(subscription.startDate)),
                  _InfoData('تاريخ النهاية', _date(subscription.endDate)),
                  _InfoData('الحالة', subscription.status.label),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          child: Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    context.read<SubscriptionsCubit>().renew(subscription.id),
                icon: const Icon(Icons.refresh),
                label: const Text('تجديد الاشتراك'),
              ),
              OutlinedButton.icon(
                onPressed: subscription.status == SubscriptionStatus.cancelled
                    ? null
                    : () => context.read<SubscriptionsCubit>().cancel(
                        subscription.id,
                      ),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('إلغاء الاشتراك'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CreateSubscriptionScreen extends StatefulWidget {
  final SubscriptionCreationOptions options;

  const CreateSubscriptionScreen({super.key, required this.options});

  @override
  State<CreateSubscriptionScreen> createState() =>
      _CreateSubscriptionScreenState();
}

class _CreateSubscriptionScreenState extends State<CreateSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  SubscriptionUserOption? _user;
  SubscriptionPlanOption? _plan;
  DateTime? _startDate;

  DateTime? get _endDate {
    final plan = _plan;
    final start = _startDate;
    if (plan == null || start == null) return null;
    return DateTime(start.year, start.month, start.day + plan.days);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: BlocListener<SubscriptionsCubit, SubscriptionsState>(
          listener: (context, state) {
            if (state is SubscriptionsActionSuccess) {
              Navigator.of(context).pop();
            }
          },
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.large),
              children: [
                DashboardModuleHeader(
                  icon: Icons.workspace_premium_outlined,
                  title: 'إنشاء اشتراك',
                  subtitle: 'اختر العميل والباقة وتاريخ البداية.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: Navigator.of(context).pop,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('إغلاق'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                AppCard(
                  child: Column(
                    children: [
                      _Dropdown<SubscriptionUserOption>(
                        label: 'اختر العميل',
                        value: _user,
                        items: widget.options.users,
                        itemLabel: (user) => '${user.name} - ${user.phone}',
                        onChanged: (value) => setState(() => _user = value),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      _Dropdown<SubscriptionPlanOption>(
                        label: 'اختر الباقة',
                        value: _plan,
                        items: widget.options.plans,
                        itemLabel: (plan) =>
                            '${plan.name} - ${_toArabicNumber(plan.price)} ${plan.currency}',
                        onChanged: (value) => setState(() => _plan = value),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تاريخ البداية'),
                        subtitle: Text(
                          _startDate == null ? 'مطلوب' : _date(_startDate!),
                        ),
                        trailing: const Icon(Icons.calendar_month_outlined),
                        onTap: _pickStartDate,
                      ),
                      const Divider(),
                      _Info(
                        label: 'سعر الباقة',
                        value: _plan == null
                            ? 'اختر الباقة'
                            : '${_toArabicNumber(_plan!.price)} ${_plan!.currency}',
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _Info(
                        label: 'تاريخ النهاية المحسوب',
                        value: _endDate == null ? 'لم يحدد بعد' : _date(_endDate!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('تأكيد الاشتراك'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (selected != null) {
      setState(() => _startDate = selected);
    }
  }

  void _submit() {
    _formKey.currentState?.validate();
    if (_user == null || _plan == null || _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل بيانات الاشتراك المطلوبة')),
      );
      return;
    }
    context.read<SubscriptionsCubit>().createManualSubscription(
      user: _user!,
      plan: _plan!,
      startDate: _startDate!,
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  final List<_InfoData> items;

  const _DetailsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.large,
      runSpacing: AppSpacing.medium,
      children: items
          .map(
            (item) => SizedBox(
              width: 220,
              child: _Info(label: item.label, value: item.value),
            ),
          )
          .toList(),
    );
  }
}

class _InfoData {
  final String label;
  final String value;

  const _InfoData(this.label, this.value);
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;

  const _Info({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _SubscriptionStatusChip extends StatelessWidget {
  final SubscriptionStatus status;

  const _SubscriptionStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SubscriptionStatus.active => AppStatusColors.onSuccessContainer,
      SubscriptionStatus.pendingPayment => AppStatusColors.onWarningContainer,
      SubscriptionStatus.expired => AppStatusColors.onNeutralContainer,
      SubscriptionStatus.cancelled => AppStatusColors.onErrorContainer,
    };
    return StatusChip(
      label: status.label,
      color: color.withAlpha(28),
      textColor: color,
    );
  }
}

String _money(UserSubscription subscription) {
  return '${_toArabicNumber(subscription.price)} ${subscription.currency}';
}

String _amount(double value) => '${_toArabicNumber(value)} ج.م';

String _date(DateTime value) {
  return _toArabicDigits(intl.DateFormat('yyyy/MM/dd').format(value));
}

String _toArabicNumber(num value) {
  final text = value is int || value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return _toArabicDigits(text);
}

String _toArabicDigits(String text) {
  return text
      .replaceAll('0', '٠')
      .replaceAll('1', '١')
      .replaceAll('2', '٢')
      .replaceAll('3', '٣')
      .replaceAll('4', '٤')
      .replaceAll('5', '٥')
      .replaceAll('6', '٦')
      .replaceAll('7', '٧')
      .replaceAll('8', '٨')
      .replaceAll('9', '٩');
}
