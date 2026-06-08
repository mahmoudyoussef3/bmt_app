import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/user_subscription.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الاشتراكات'),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.medium),
              child: FilledButton.icon(
                onPressed: () => _openCreate(context),
                icon: const Icon(Icons.add),
                label: const Text('اشتراك جديد'),
              ),
            ),
          ],
        ),
        body: BlocConsumer<SubscriptionsCubit, SubscriptionsState>(
          listener: (context, state) {
            if (state is SubscriptionsActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return switch (state) {
              SubscriptionsInitial() || SubscriptionsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              SubscriptionsError(:final message) => Center(
                child: Text(message),
              ),
              SubscriptionsLoaded() => _SubscriptionsListView(state: state),
              SubscriptionsActionSuccess() => _SubscriptionsListView(
                state: SubscriptionsLoaded(
                  subscriptions: state.subscriptions,
                  creationOptions: state.creationOptions,
                ),
              ),
              SubscriptionDetailsLoaded() => SubscriptionDetailsScreen(
                subscription: state.subscription,
              ),
            };
          },
        ),
      ),
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

class _SubscriptionsListView extends StatelessWidget {
  final SubscriptionsLoaded state;

  const _SubscriptionsListView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined, size: 40),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Text(
                      'الاشتراكات',
                      style: Theme.of(context).textTheme.headlineSmall,
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
              _Info(label: 'المسار', value: subscription.routeName),
              _Info(
                label: 'الجزء',
                value:
                    '${subscription.fromPointName} → ${subscription.toPointName}',
              ),
              _Info(label: 'نوع الاشتراك', value: subscription.type.label),
              _Info(label: 'السعر', value: _money(subscription)),
              _Info(
                label: 'الرحلات المتبقية',
                value: _toArabicNumber(subscription.remainingRides),
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
                  _InfoData('رقم العميل', subscription.userId),
                ],
              ),
              const Divider(height: AppSpacing.large),
              _SectionTitle('بيانات الرحلة والمسار'),
              _DetailsGrid(
                items: [
                  _InfoData('رقم الرحلة', subscription.tripId),
                  _InfoData('رقم المسار', subscription.routeId),
                  _InfoData('المسار', subscription.routeName),
                  _InfoData(
                    'الجزء',
                    '${subscription.fromPointName} → ${subscription.toPointName}',
                  ),
                ],
              ),
              const Divider(height: AppSpacing.large),
              _SectionTitle('بيانات الاشتراك'),
              _DetailsGrid(
                items: [
                  _InfoData('نوع الاشتراك', subscription.type.label),
                  _InfoData('السعر', _money(subscription)),
                  _InfoData('حالة الدفع', _paymentLabel(subscription.status)),
                  _InfoData(
                    'إجمالي الرحلات',
                    _toArabicNumber(subscription.totalRides),
                  ),
                  _InfoData(
                    'الرحلات المستخدمة',
                    _toArabicNumber(subscription.usedRides),
                  ),
                  _InfoData(
                    'الرحلات المتبقية',
                    _toArabicNumber(subscription.remainingRides),
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
                onPressed: () =>
                    context.read<SubscriptionsCubit>().cancel(subscription.id),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('إلغاء الاشتراك'),
              ),
              OutlinedButton.icon(
                onPressed: subscription.remainingRides == 0
                    ? null
                    : () => context.read<SubscriptionsCubit>().markRideUsed(
                        subscription.id,
                      ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تسجيل رحلة مستخدمة'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('عرض المدفوعات سيتم ربطه لاحقًا'),
                    ),
                  );
                },
                icon: const Icon(Icons.payments_outlined),
                label: const Text('عرض المدفوعات'),
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
  SubscriptionTripOption? _trip;
  SubscriptionPointOption? _fromPoint;
  SubscriptionPointOption? _toPoint;
  SubscriptionType? _type;
  DateTime? _startDate;

  SubscriptionPricingOption? get _pricing {
    final trip = _trip;
    final fromPoint = _fromPoint;
    final toPoint = _toPoint;
    final type = _type;
    if (trip == null || fromPoint == null || toPoint == null || type == null) {
      return null;
    }
    for (final pricing in trip.pricing) {
      if (pricing.fromPointId == fromPoint.id &&
          pricing.toPointId == toPoint.id &&
          pricing.type == type) {
        return pricing;
      }
    }
    return null;
  }

  DateTime? get _endDate {
    final type = _type;
    final startDate = _startDate;
    if (type == null || startDate == null) return null;
    return SubscriptionsCubit.endDateFor(type, startDate);
  }

  @override
  Widget build(BuildContext context) {
    final points = _trip?.points ?? const <SubscriptionPointOption>[];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء اشتراك')),
        body: BlocListener<SubscriptionsCubit, SubscriptionsState>(
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
                      _Dropdown<SubscriptionTripOption>(
                        label: 'اختر الرحلة',
                        value: _trip,
                        items: widget.options.trips,
                        itemLabel: (trip) => trip.routeName,
                        onChanged: (value) => setState(() {
                          _trip = value;
                          _fromPoint = null;
                          _toPoint = null;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Row(
                        children: [
                          Expanded(
                            child: _Dropdown<SubscriptionPointOption>(
                              label: 'من نقطة',
                              value: _fromPoint,
                              items: points,
                              itemLabel: (point) => point.name,
                              onChanged: (value) =>
                                  setState(() => _fromPoint = value),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: _Dropdown<SubscriptionPointOption>(
                              label: 'إلى نقطة',
                              value: _toPoint,
                              items: points
                                  .where(
                                    (point) =>
                                        _fromPoint == null ||
                                        point.order > _fromPoint!.order,
                                  )
                                  .toList(),
                              itemLabel: (point) => point.name,
                              onChanged: (value) =>
                                  setState(() => _toPoint = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      _Dropdown<SubscriptionType>(
                        label: 'نوع الاشتراك',
                        value: _type,
                        items: SubscriptionType.values,
                        itemLabel: (type) => type.label,
                        onChanged: (value) => setState(() => _type = value),
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
                        label: 'السعر من تسعير الرحلة',
                        value: _pricing == null
                            ? 'اختر الجزء ونوع الاشتراك'
                            : '${_toArabicNumber(_pricing!.price)} ${_pricing!.currency}',
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _Info(
                        label: 'تاريخ النهاية المحسوب',
                        value: _endDate == null
                            ? 'لم يحدد بعد'
                            : _date(_endDate!),
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
    final missing =
        _user == null ||
        _trip == null ||
        _fromPoint == null ||
        _toPoint == null ||
        _type == null ||
        _startDate == null;
    if (missing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل بيانات الاشتراك المطلوبة')),
      );
      return;
    }
    if (_pricing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('السعر يجب أن يكون مسجلًا في تسعير الرحلة'),
        ),
      );
      return;
    }
    context.read<SubscriptionsCubit>().createManualSubscription(
      user: _user!,
      trip: _trip!,
      fromPoint: _fromPoint!,
      toPoint: _toPoint!,
      type: _type!,
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
      SubscriptionStatus.active => Colors.green,
      SubscriptionStatus.pendingPayment => Colors.orange,
      SubscriptionStatus.expired => Colors.blueGrey,
      SubscriptionStatus.cancelled => Colors.red,
    };
    return StatusChip(
      label: status.label,
      color: color.withAlpha(28),
      textColor: color.shade700,
    );
  }
}

String _paymentLabel(SubscriptionStatus status) {
  return status == SubscriptionStatus.pendingPayment
      ? 'بانتظار الدفع'
      : 'لا يوجد دفع إلكتروني';
}

String _money(UserSubscription subscription) {
  return '${_toArabicNumber(subscription.price)} ${subscription.currency}';
}

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
