import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../cubit/vehicles_cubit.dart';
import '../cubit/vehicles_state.dart';
import '../widgets/vehicle_details_view.dart';
import '../widgets/vehicle_grid.dart';
import '../widgets/vehicle_top_dashboard.dart';
import '../widgets/vehicle_wizard_view.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehiclesCubit, VehiclesState>(
      builder: (context, state) {
        return switch (state) {
          VehiclesLoading() => const Center(child: CircularProgressIndicator()),
          VehiclesError(:final message) => _VehiclesError(message: message),
          VehiclesLoaded() => _VehiclesLoadedView(state: state),
        };
      },
    );
  }
}

class _VehiclesLoadedView extends StatelessWidget {
  final VehiclesLoaded state;

  const _VehiclesLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VehiclesCubit>();
    final selected = state.selectedVehicle;

    return switch (state.view) {
      VehiclesView.details => VehicleDetailsView(
        vehicle: selected ?? state.vehicles.first,
        onBack: cubit.showGrid,
        onEdit: () => cubit.showEdit(selected ?? state.vehicles.first),
        onStatusChanged: (status) =>
            cubit.updateVehicleStatus(selected ?? state.vehicles.first, status),
        onRenewDocument: (title) =>
            cubit.renewDocument(selected ?? state.vehicles.first, title),
      ),
      VehiclesView.create => VehicleWizardView(
        onSubmit: cubit.saveVehicle,
        onCancel: cubit.showGrid,
      ),
      VehiclesView.edit => VehicleWizardView(
        vehicle: selected,
        onSubmit: cubit.saveVehicle,
        onCancel: () {
          if (selected == null) {
            cubit.showGrid();
          } else {
            cubit.showDetails(selected);
          }
        },
      ),
      VehiclesView.grid => _FleetGridView(state: state),
    };
  }
}

class _FleetGridView extends StatelessWidget {
  final VehiclesLoaded state;

  const _FleetGridView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VehiclesCubit>();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة الأسطول',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      'متابعة أصول المركبات، المستندات، الصيانة، والتعيين التشغيلي.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'إضافة مركبة',
                height: 40,
                onPressed: cubit.showCreate,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        VehicleTopDashboard(state: state),
        const SizedBox(height: AppSpacing.large),
        VehicleGrid(
          vehicles: state.filteredVehicles,
          filters: state.filters,
          onSearchChanged: cubit.updateSearch,
          onStatusChanged: cubit.updateStatusFilter,
          onVehicleSelected: cubit.showDetails,
        ),
      ],
    );
  }
}

class _VehiclesError extends StatelessWidget {
  final String message;

  const _VehiclesError({required this.message});

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
              onPressed: () => context.read<VehiclesCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}
