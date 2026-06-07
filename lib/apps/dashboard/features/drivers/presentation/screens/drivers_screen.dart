import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/driver.dart';
import '../cubit/drivers_cubit.dart';
import '../cubit/drivers_state.dart';
import '../widgets/driver_details_view.dart';
import '../widgets/driver_form_view.dart';
import '../widgets/driver_summary_cards.dart';
import '../widgets/driver_table.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriversCubit, DriversState>(
      builder: (context, state) {
        return switch (state) {
          DriversLoading() => const Center(child: CircularProgressIndicator()),
          DriversError(:final message) => _DriversError(message: message),
          DriversLoaded() => _DriversLoadedView(state: state),
        };
      },
    );
  }
}

class _DriversLoadedView extends StatelessWidget {
  final DriversLoaded state;

  const _DriversLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriversCubit>();

    return switch (state.view) {
      DriversView.details => DriverDetailsView(
        driver: state.selectedDriver ?? state.drivers.first,
        onBack: cubit.showList,
        onEdit: () =>
            cubit.showEdit(state.selectedDriver ?? state.drivers.first),
        onDelete: () => _confirmDelete(
          context,
          state.selectedDriver ?? state.drivers.first,
        ),
        onStatusChanged: (status) => cubit.updateDriverStatus(
          state.selectedDriver ?? state.drivers.first,
          status,
        ),
      ),
      DriversView.create => DriverFormView(
        onSubmit: cubit.saveDriver,
        onCancel: cubit.showList,
      ),
      DriversView.edit => DriverFormView(
        driver: state.selectedDriver,
        onSubmit: cubit.saveDriver,
        onCancel: () {
          final driver = state.selectedDriver;
          if (driver == null) {
            cubit.showList();
          } else {
            cubit.showDetails(driver);
          }
        },
      ),
      DriversView.archive => _DriverListView(state: state, archive: true),
      DriversView.list => _DriverListView(state: state),
    };
  }
}

class _DriverListView extends StatelessWidget {
  final DriversLoaded state;
  final bool archive;

  const _DriverListView({required this.state, this.archive = false});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriversCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _DriversHeader(archive: archive),
        const SizedBox(height: AppSpacing.large),
        DriverSummaryCards(drivers: state.drivers),
        const SizedBox(height: AppSpacing.large),
        DriverTable(
          drivers: state.pagedDrivers,
          query: state.query,
          totalCount: state.filteredDrivers.length,
          maxPage: state.maxPage,
          onSearchChanged: cubit.updateSearch,
          onStatusChanged: cubit.updateStatusFilter,
          onSortChanged: cubit.updateSort,
          onPageChanged: cubit.updatePage,
          onView: cubit.showDetails,
          onEdit: cubit.showEdit,
          onStatusAction: cubit.updateDriverStatus,
        ),
      ],
    );
  }
}

class _DriversHeader extends StatelessWidget {
  final bool archive;

  const _DriversHeader({required this.archive});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriversCubit>();
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  archive ? 'أرشيف السائقين' : 'قائمة السائقين',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  archive
                      ? 'السائقين الموقوفين أو غير النشطين في التشغيل.'
                      : 'إدارة بيانات السائقين، الحالة، المستندات، والتشغيل اليومي.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              AppButton(
                label: archive ? 'رجوع للقائمة' : 'أرشيف السائقين',
                height: 40,
                outline: true,
                onPressed: archive ? cubit.showList : cubit.showArchive,
              ),
              if (!archive)
                AppButton(
                  label: 'إضافة سائق',
                  height: 40,
                  onPressed: cubit.showCreate,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriversError extends StatelessWidget {
  final String message;

  const _DriversError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.medium),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<DriversCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}

void _confirmDelete(BuildContext context, Driver driver) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<DriversCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف السائق'),
          content: Text('هل تريد حذف ${driver.name} من البيانات التجريبية؟'),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                context.read<DriversCubit>().deleteDriver(driver);
                Navigator.of(context).pop();
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    ),
  );
}
