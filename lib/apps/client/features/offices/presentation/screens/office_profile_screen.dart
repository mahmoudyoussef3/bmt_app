import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';
import '../cubit/office_profile_cubit.dart';
import '../cubit/office_profile_state.dart';
import '../widgets/office_profile_header.dart';
import '../widgets/office_route_tile.dart';

/// One office's marketplace profile: identity + rating, then the routes it
/// operates. A route tap re-enters the existing booking search pre-filtered
/// to that route — this screen owns no booking logic of its own.
class OfficeProfileScreen extends StatelessWidget {
  const OfficeProfileScreen({super.key, required this.office});

  final OfficeSummary office;

  void _openRoute(BuildContext context, String routeId) {
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: BookingSearchQuery(routeId: routeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          office.name,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w800),
        ),
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          OfficeProfileHeader(office: office),
          const SizedBox(height: 20),
          ClientSectionHeader(title: context.l10n.offices_routesHeader),
          const SizedBox(height: 4),
          BlocBuilder<OfficeProfileCubit, OfficeProfileState>(
            builder: (context, state) => switch (state) {
              OfficeProfileLoading() => const _RoutesSkeleton(),
              OfficeProfileError(:final message) => ClientErrorCard(
                message: message,
                retryLabel: context.l10n.common_retry,
                onRetry: () =>
                    context.read<OfficeProfileCubit>().load(office.id),
              ),
              OfficeProfileLoaded(:final routes) => routes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        context.l10n.offices_noRoutes,
                        style: ClientTypography.bodyMedium(context),
                      ),
                    )
                  : Column(
                      children: [
                        for (final route in routes) ...[
                          OfficeRouteTile(
                            route: route,
                            onTap: () => _openRoute(context, route.id),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            },
          ),
        ],
      ),
    );
  }
}

class _RoutesSkeleton extends StatelessWidget {
  const _RoutesSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ClientSkeleton(height: 68, borderRadius: 16),
        SizedBox(height: 12),
        ClientSkeleton(height: 68, borderRadius: 16),
      ],
    );
  }
}
