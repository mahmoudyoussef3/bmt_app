import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/package_pricing.dart';
import '../cubit/packages_cubit.dart';
import '../cubit/packages_state.dart';

class PackagesOverviewScreen extends StatelessWidget {
  const PackagesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackagesCubit, PackagesState>(
      builder: (context, state) {
        return switch (state) {
          PackagesInitial() ||
          PackagesLoading() => const Center(child: CircularProgressIndicator()),
          PackagesError(:final message) => _ErrorState(message: message),
          PackagePlansLoaded() => _PackagesContent(state: state),
          TripPackagePricesLoaded() => const _EmptyState(
            message: 'تسعير الرحلات سيضاف في المرحلة التالية.',
          ),
          PackagesActionSuccess(:final message) => _EmptyState(
            message: message,
          ),
        };
      },
    );
  }
}

class _PackagesContent extends StatelessWidget {
  final PackagePlansLoaded state;

  const _PackagesContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PackagesCubit>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _Header(state: state),
        const SizedBox(height: AppSpacing.large),
        _Tabs(view: state.view),
        const SizedBox(height: AppSpacing.large),
        switch (state.view) {
          PackagesView.overview => _PlansOverview(plans: state.plans),
          PackagesView.routePricing => _RoutePricingWorkspace(state: state),
        },
        const SizedBox(height: AppSpacing.large),
        if (state.view == PackagesView.routePricing)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: cubit.showOverview,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('رجوع للباقات'),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final PackagePlansLoaded state;

  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الباقات والأسعار',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'إدارة أنواع الباقات وأسعارها حسب المسار أو جزء من المسار.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.read<PackagesCubit>().showRoutePricing(),
            icon: const Icon(Icons.alt_route_rounded),
            label: const Text('تسعير نقاط المسار'),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final PackagesView view;

  const _Tabs({required this.view});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PackagesCubit>();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xSmall),
      child: Row(
        children: [
          _TabButton(
            label: 'الباقات',
            selected: view == PackagesView.overview,
            onPressed: cubit.showOverview,
          ),
          _TabButton(
            label: 'أسعار نقاط المسار',
            selected: view == PackagesView.routePricing,
            onPressed: () => cubit.showRoutePricing(),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xSmall),
        child: selected
            ? FilledButton(onPressed: onPressed, child: Text(label))
            : TextButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}

class _PlansOverview extends StatelessWidget {
  final List<PackagePlanEntity> plans;

  const _PlansOverview({required this.plans});

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const _EmptyState(message: 'لا توجد باقات مسجلة حتى الآن.');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 3
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plans.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 214,
          ),
          itemBuilder: (context, index) => _PlanCard(plan: plans[index]),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PackagePlanEntity plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<PackagesCubit>();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.nameAr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(label: plan.isActive ? 'نشط' : 'غير نشط'),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            plan.descriptionAr,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            '${plan.price.toStringAsFixed(0)} ${plan.currency}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _openPlanEditor(context, plan),
                child: const Text('تعديل'),
              ),
              const SizedBox(width: AppSpacing.small),
              TextButton(
                onPressed: () => cubit.togglePlan(plan.id),
                child: Text(plan.isActive ? 'إيقاف' : 'تفعيل'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutePricingWorkspace extends StatefulWidget {
  final PackagePlansLoaded state;

  const _RoutePricingWorkspace({required this.state});

  @override
  State<_RoutePricingWorkspace> createState() => _RoutePricingWorkspaceState();
}

class _RoutePricingWorkspaceState extends State<_RoutePricingWorkspace> {
  late PackageRouteEntity selectedRoute = widget.state.selectedRoute;
  late RoutePointEntity fromPoint = selectedRoute.points.first;
  late RoutePointEntity toPoint = selectedRoute.points.last;
  late PackagePlanEntity selectedPlan = widget.state.plans.first;
  final price = TextEditingController();
  String error = '';

  @override
  void dispose() {
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<PackagesCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                      selectedRoute.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    const Text(
                      'حدد بداية ونهاية الاشتراك ثم نوع الباقة والسعر.',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedRoute.id,
                  decoration: const InputDecoration(labelText: 'المسار'),
                  items: state.routes
                      .map(
                        (route) => DropdownMenuItem(
                          value: route.id,
                          child: Text(route.name),
                        ),
                      )
                      .toList(),
                  onChanged: (routeId) {
                    final route = state.routes.firstWhere(
                      (item) => item.id == routeId,
                    );
                    setState(() {
                      selectedRoute = route;
                      fromPoint = route.points.first;
                      toPoint = route.points.last;
                      error = '';
                    });
                    cubit.showRoutePricing(route: route);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1000;
            final timeline = _RouteTimeline(route: selectedRoute);
            final editor = _RoutePriceEditor(
              route: selectedRoute,
              fromPoint: fromPoint,
              toPoint: toPoint,
              selectedPlan: selectedPlan,
              plans: state.plans,
              price: price,
              error: error,
              onFromChanged: (point) => setState(() => fromPoint = point),
              onToChanged: (point) => setState(() => toPoint = point),
              onPlanChanged: (plan) => setState(() => selectedPlan = plan),
              onSave: _savePrice,
            );
            if (compact) {
              return Column(
                children: [
                  timeline,
                  const SizedBox(height: AppSpacing.medium),
                  editor,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: timeline),
                const SizedBox(width: AppSpacing.medium),
                Expanded(flex: 3, child: editor),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.large),
        _RoutePricesTable(prices: state.routePrices),
      ],
    );
  }

  Future<void> _savePrice() async {
    final value = double.tryParse(price.text.trim());
    if (fromPoint.id == toPoint.id) {
      setState(() => error = 'نقطة البداية لا يمكن أن تساوي نقطة الوصول');
      return;
    }
    if (fromPoint.order >= toPoint.order) {
      setState(() => error = 'نقطة البداية يجب أن تكون قبل نقطة الوصول');
      return;
    }
    if (value == null || value <= 0) {
      setState(() => error = 'السعر يجب أن يكون أكبر من صفر');
      return;
    }
    final result = await context.read<PackagesCubit>().saveRoutePrice(
      RoutePackagePriceEntity(
        id: '',
        routeId: selectedRoute.id,
        routeName: selectedRoute.name,
        fromPointId: fromPoint.id,
        fromPointName: fromPoint.name,
        toPointId: toPoint.id,
        toPointName: toPoint.name,
        packagePlanId: selectedPlan.id,
        packageName: selectedPlan.nameAr,
        price: value,
        currency: selectedPlan.currency,
        isActive: true,
      ),
    );
    if (result != null) {
      setState(() => error = result);
      return;
    }
    price.clear();
    setState(() => error = '');
  }
}

class _RouteTimeline extends StatelessWidget {
  final PackageRouteEntity route;

  const _RouteTimeline({required this.route});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نقاط المسار', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.medium),
          ...route.points.map((point) {
            final last = point.order == route.points.length;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(radius: 15, child: Text('${point.order}')),
                    if (!last)
                      Container(
                        width: 2,
                        height: 42,
                        color: scheme.outline.withAlpha(120),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: Text(
                      point.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _RoutePriceEditor extends StatelessWidget {
  final PackageRouteEntity route;
  final RoutePointEntity fromPoint;
  final RoutePointEntity toPoint;
  final PackagePlanEntity selectedPlan;
  final List<PackagePlanEntity> plans;
  final TextEditingController price;
  final String error;
  final ValueChanged<RoutePointEntity> onFromChanged;
  final ValueChanged<RoutePointEntity> onToChanged;
  final ValueChanged<PackagePlanEntity> onPlanChanged;
  final VoidCallback onSave;

  const _RoutePriceEditor({
    required this.route,
    required this.fromPoint,
    required this.toPoint,
    required this.selectedPlan,
    required this.plans,
    required this.price,
    required this.error,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPlanChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حدد بداية ونهاية الاشتراك',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: fromPoint.id,
                  decoration: const InputDecoration(labelText: 'نقطة البداية'),
                  items: route.points
                      .map(
                        (point) => DropdownMenuItem(
                          value: point.id,
                          child: Text(point.name),
                        ),
                      )
                      .toList(),
                  onChanged: (id) => onFromChanged(
                    route.points.firstWhere((point) => point.id == id),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: toPoint.id,
                  decoration: const InputDecoration(labelText: 'نقطة الوصول'),
                  items: route.points
                      .map(
                        (point) => DropdownMenuItem(
                          value: point.id,
                          child: Text(point.name),
                        ),
                      )
                      .toList(),
                  onChanged: (id) => onToChanged(
                    route.points.firstWhere((point) => point.id == id),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: plans.map((plan) {
              final selected = plan.id == selectedPlan.id;
              return selected
                  ? FilledButton(
                      onPressed: () => onPlanChanged(plan),
                      child: Text(plan.nameAr),
                    )
                  : OutlinedButton(
                      onPressed: () => onPlanChanged(plan),
                      child: Text(plan.nameAr),
                    );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: price,
                  decoration: const InputDecoration(labelText: 'السعر'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              _ReadonlyValue(label: 'العملة', value: selectedPlan.currency),
            ],
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ السعر'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePricesTable extends StatelessWidget {
  final List<RoutePackagePriceEntity> prices;

  const _RoutePricesTable({required this.prices});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('أسعار مسجلة', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.medium),
          if (prices.isEmpty)
            const _EmptyState(message: 'لا توجد أسعار لهذا المسار بعد.')
          else
            ...prices.map(
              (price) => Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                margin: const EdgeInsets.only(bottom: AppSpacing.small),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withAlpha(60),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${price.fromPointName} ← ${price.toPointName}',
                      ),
                    ),
                    Expanded(child: Text(price.packageName)),
                    Text('${price.price.toStringAsFixed(0)} ${price.currency}'),
                    const SizedBox(width: AppSpacing.medium),
                    StatusChip(label: price.isActive ? 'نشط' : 'غير نشط'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _openPlanEditor(BuildContext context, PackagePlanEntity plan) {
  final price = TextEditingController(text: plan.price.toStringAsFixed(0));
  var active = plan.isActive;
  showDialog<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تعديل ${plan.nameAr}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReadonlyValue(label: 'نوع الباقة', value: plan.nameAr),
                const SizedBox(height: AppSpacing.small),
                TextField(
                  controller: price,
                  decoration: const InputDecoration(labelText: 'السعر'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.small),
                _ReadonlyValue(label: 'العملة', value: plan.currency),
                SwitchListTile(
                  value: active,
                  onChanged: (value) => setState(() => active = value),
                  title: const Text('نشط'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(price.text.trim());
                if (value == null || value <= 0) return;
                context.read<PackagesCubit>().savePlan(
                  plan.copyWith(price: value, isActive: active),
                );
                Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReadonlyValue extends StatelessWidget {
  final String label;
  final String value;

  const _ReadonlyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Center(child: Text(message)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.medium),
            FilledButton(
              onPressed: context.read<PackagesCubit>().load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
