import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/route_details.dart';
import '../cubit/route_details_cubit.dart';
import '../cubit/route_details_state.dart';
import '../widgets/route_stop_timeline.dart';

/// One route's full record: identity, the office running it, and every stop
/// on its corridor — pushed from the routes catalog.
///
/// Booking is deliberately handed off rather than reimplemented here: the CTA
/// pushes into the existing search flow pre-filtered to this route, the same
/// way [OfficeProfileScreen] hands a tapped corridor to booking search.
class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({super.key, required this.routeId});

  final String routeId;

  void _bookRoute(BuildContext context, RouteDetails details) {
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: BookingSearchQuery(routeId: details.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      body: BlocBuilder<RouteDetailsCubit, RouteDetailsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              ClientSliverAppBar(
                title: state is RouteDetailsLoaded
                    ? state.details.name
                    : l10n.nav_routes,
              ),
              SliverToBoxAdapter(
                child: switch (state) {
                  RouteDetailsLoading() => const _DetailsSkeleton(),
                  RouteDetailsError(:final message) => Padding(
                    padding: const EdgeInsets.all(ClientSpacing.md),
                    child: ClientErrorCard(
                      message: message,
                      retryLabel: l10n.common_retry,
                      onRetry: () => context.read<RouteDetailsCubit>().load(
                        routeId,
                      ),
                    ),
                  ),
                  RouteDetailsLoaded(:final details) => _Body(
                    details: details,
                  ),
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<RouteDetailsCubit, RouteDetailsState>(
        builder: (context, state) {
          if (state is! RouteDetailsLoaded) return const SizedBox.shrink();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ClientSpacing.md,
                ClientSpacing.sm,
                ClientSpacing.md,
                ClientSpacing.sm,
              ),
              child: ClientButton(
                label: l10n.routes_bookThisRoute,
                onPressed: () => _bookRoute(context, state.details),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.details});

  final RouteDetails details;

  bool get _hasEndpoints =>
      details.startCity.isNotEmpty && details.endCity.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.officeName.isNotEmpty) ...[
            Row(
              children: [
                if (details.officeLogoUrl?.isNotEmpty ?? false)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ClientRadius.xs),
                    child: Image.network(
                      details.officeLogoUrl!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(width: ClientSpacing.xs),
                Flexible(
                  child: Text(
                    l10n.routes_operatedBy(details.officeName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.labelMedium(context).copyWith(
                      color: ClientColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClientSpacing.md),
          ],
          if (_hasEndpoints)
            ClientCard(
              child: Row(
                children: [
                  Expanded(
                    child: _Endpoint(
                      label: details.startCity,
                      align: CrossAxisAlignment.start,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: ClientColors.primaryFor(context),
                  ),
                  Expanded(
                    child: _Endpoint(
                      label: details.endCity,
                      align: CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: ClientSpacing.sm),
          if (details.distance.isNotEmpty || details.duration.isNotEmpty)
            Row(
              children: [
                if (details.distance.isNotEmpty)
                  Expanded(
                    child: _MetaTile(
                      icon: Icons.route_outlined,
                      value: details.distance,
                    ),
                  ),
                if (details.distance.isNotEmpty && details.duration.isNotEmpty)
                  const SizedBox(width: ClientSpacing.xs),
                if (details.duration.isNotEmpty)
                  Expanded(
                    child: _MetaTile(
                      icon: Icons.schedule_rounded,
                      value: details.duration,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: ClientSpacing.lg),
          Text(
            l10n.routes_stopsCount(details.stops.length),
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: ClientSpacing.sm),
          RouteStopTimeline(stops: details.stops),
          const SizedBox(height: ClientSpacing.xl),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.label, required this.align});

  final String label;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: align == CrossAxisAlignment.end
              ? TextAlign.end
              : TextAlign.start,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.md,
        vertical: ClientSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ClientColors.primaryFor(context)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClientSkeleton(height: 84, borderRadius: ClientRadius.lg),
          const SizedBox(height: ClientSpacing.sm),
          ClientSkeleton(height: 44, borderRadius: ClientRadius.lg),
          const SizedBox(height: ClientSpacing.lg),
          ClientSkeleton(height: 20, width: 100, borderRadius: 6),
          const SizedBox(height: ClientSpacing.sm),
          ClientSkeleton(height: 108, borderRadius: ClientRadius.lg),
        ],
      ),
    );
  }
}
