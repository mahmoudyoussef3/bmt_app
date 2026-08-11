import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

import '../../domain/entities/route_draft.dart';
import '../../domain/services/route_identity.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import '../widgets/route_builder/route_builder_view.dart';
import '../widgets/route_details_view.dart';
import '../widgets/routes_list_view.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutesCubit, RoutesState>(
      listenWhen: (previous, current) =>
          current is RoutesLoaded &&
          (current.flashMessage.isNotEmpty || current.actionError.isNotEmpty),
      listener: (context, state) {
        if (state is! RoutesLoaded) return;
        if (state.flashMessage.isNotEmpty) {
          AppSnackbar.success(context, state.flashMessage);
          return;
        }
        
        if (state.view != RoutesView.form) {
          AppSnackbar.error(context, state.actionError);
        }
      },
      builder: (context, state) {
        return switch (state) {
          RoutesLoading() => const DashboardLoading(rows: 5),
          RoutesError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<RoutesCubit>().load(),
          ),
          RoutesLoaded() => switch (state.view) {
            RoutesView.list => RoutesListView(state: state),
            RoutesView.details => RouteDetailsView(state: state),
            RoutesView.form => _RouteBuilderHost(state: state),
          },
        };
      },
    );
  }
}

/// Mounts the builder and wires it back to the module: cancel returns where the
/// operator came from, save goes through the routes cubit.
class _RouteBuilderHost extends StatelessWidget {
  final RoutesLoaded state;

  const _RouteBuilderHost({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final editing = state.editingRoute;
    final reverseOf = state.reverseOf;

    final draft = reverseOf == null
        ? null
        : RouteDraft.fromRoute(reverseOf).reversedLeg(
            suggestedCode: RouteIdentity.suggestCode(state.routeCodes),
          );

    return RouteBuilderView(
      
      key: ValueKey(
        'route-builder-${editing?.id ?? (reverseOf == null ? 'new' : 'return-${reverseOf.id}')}',
      ),
      route: editing,
      draft: draft,
      existingCodes: state.routeCodes,
      library: state.stopLibrary,
      saving: state.saving,
      saveError: state.actionError,
      onCancel: () {
        if (editing != null) {
          cubit.showDetails(editing);
        } else if (reverseOf != null) {
          cubit.showDetails(reverseOf);
        } else {
          cubit.showOperations();
        }
      },
      onSave: cubit.saveRoute,
    );
  }
}
