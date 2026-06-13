import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_option_card.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Lists available route options for the current search.
class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  late BookingSearchQuery _query;
  String? _selectedRouteId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _query = bookingQueryFromContext(context);
    context.read<BookingCubit>().loadRoutes(_query);
  }

  void _continueToTrips() {
    Navigator.pushNamed(
      context,
      BookingRoutes.vehicleListing,
      arguments: _query.toArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final routes = state is BookingRoutesLoaded
            ? state.routes
            : <RouteOptionData>[];
        _selectedRouteId ??= routes.isEmpty ? null : routes.first.id;

        return BookingFlowScaffold(
          title: AppLocalizations.of(context)!.booking_selectRoute,
          query: _query,
          bottomBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppButton(
                label: AppLocalizations.of(context)!.booking_compareVehicles,
                height: 52,
                onPressed: _selectedRouteId == null ? () {} : _continueToTrips,
              ),
            ),
          ),
          body: _RouteSelectionBody(
            state: state,
            routes: routes,
            selectedRouteId: _selectedRouteId,
            onRetry: () => context.read<BookingCubit>().loadRoutes(_query),
            onMap: () {
              Navigator.pushNamed(
                context,
                BookingRoutes.mapSelection,
                arguments: _query.toArguments(),
              );
            },
            onSelect: (routeId) => setState(() => _selectedRouteId = routeId),
          ),
        );
      },
    );
  }
}

class _RouteSelectionBody extends StatelessWidget {
  const _RouteSelectionBody({
    required this.state,
    required this.routes,
    required this.selectedRouteId,
    required this.onRetry,
    required this.onMap,
    required this.onSelect,
  });

  final BookingState state;
  final List<RouteOptionData> routes;
  final String? selectedRouteId;
  final VoidCallback onRetry;
  final VoidCallback onMap;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (state is BookingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is BookingError) {
      return _BookingErrorState(
        message: (state as BookingError).message,
        onRetry: onRetry,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        SectionHeader(
          title: AppLocalizations.of(context)!.booking_availableRoutes,
          subtitle: AppLocalizations.of(context)!.booking_optionsForSearch(routes.length),
          action: TextButton(onPressed: onMap, child: Text(AppLocalizations.of(context)!.booking_map)),
        ),
        const SizedBox(height: 12),
        ...routes.map((route) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RouteOptionCard(
              route: route,
              selected: selectedRouteId == route.id,
              onTap: () => onSelect(route.id),
            ),
          );
        }),
      ],
    );
  }
}

class _BookingErrorState extends StatelessWidget {
  const _BookingErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(AppLocalizations.of(context)!.common_tryAgain)),
          ],
        ),
      ),
    );
  }
}
