import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';
import '../../domain/entities/office_trip.dart';
import '../cubit/office_profile_cubit.dart';
import '../cubit/office_profile_state.dart';
import '../widgets/office_departures_section.dart';
import '../widgets/office_empty_note.dart';
import '../widgets/office_nothing_listed_view.dart';
import '../widgets/office_profile_header.dart';
import '../widgets/office_profile_section.dart';
import '../widgets/office_profile_stats.dart';
import '../widgets/office_profile_top_bar.dart';
import '../widgets/office_routes_section.dart';

/// One office's marketplace profile: identity + rating, the departures it is
/// selling right now, and the corridors it runs.
///
/// The screen is a storefront — a brand band carrying the operator's card, then
/// what it has for sale. Departures come first because they are what a rider
/// can act on today; the route list is the fallback for a date the board does
/// not reach. Both hand off to the existing booking search — this screen owns
/// no booking logic.
///
/// Packages are deliberately absent. A plan has no price until a route prices
/// it, so a catalogue here could only ever say "priced later" — the plans now
/// appear on Route Details, where the corridor exists to quote them against.
class OfficeProfileScreen extends StatefulWidget {
  const OfficeProfileScreen({super.key, required this.office});

  final OfficeSummary office;

  @override
  State<OfficeProfileScreen> createState() => _OfficeProfileScreenState();
}

class _OfficeProfileScreenState extends State<OfficeProfileScreen> {
  final _scroll = ScrollController();
  final _departuresKey = GlobalKey();
  final _routesKey = GlobalKey();

  /// How far the masthead's identity has left the screen, 0→1. Drives the top
  /// bar alone, so it is a notifier rather than screen state: a departure board
  /// must not rebuild on every scroll frame.
  final _barProgress = ValueNotifier<double>(0);

  /// The name reaches the bar as the card carrying it clears the chrome. Below
  /// [_fadeStart] the two would be printed at once; by [_fadeEnd] the card's
  /// title has gone.
  static const double _fadeStart = 90;
  static const double _fadeEnd = 190;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _barProgress.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    _barProgress.value = ((offset - _fadeStart) / (_fadeEnd - _fadeStart))
        .clamp(0.0, 1.0);
  }

  double get _chromeHeight =>
      MediaQuery.paddingOf(context).top + OfficeProfileTopBar.height;

  void _openRoute(String routeId) {
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: BookingSearchQuery(routeId: routeId),
    );
  }

  /// Carries the exact departure the rider tapped into the booking flow, so the
  /// route, date and time are already chosen when they land there.
  void _openTrip(OfficeTrip trip) {
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: BookingSearchQuery(
        routeId: trip.routeId,
        pickup: trip.pickup,
        destination: trip.destination,
        date: trip.tripDate,
        time: trip.departureTime,
      ),
    );
  }

  /// Jumps to a section's heading, parked clear of the floating bar —
  /// `ensureVisible` alone would leave the heading underneath it.
  Future<void> _scrollToSection(OfficeProfileSection section) async {
    final key = switch (section) {
      OfficeProfileSection.departures => _departuresKey,
      OfficeProfileSection.routes => _routesKey,
    };
    final target = key.currentContext?.findRenderObject();
    if (target is! RenderBox || !_scroll.hasClients) return;

    final reveal = RenderAbstractViewport.of(
      target,
    ).getOffsetToReveal(target, 0).offset;
    final position = _scroll.position;

    await _scroll.animateTo(
      (reveal - _chromeHeight - ClientSpacing.sm).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: ClientMotion.base,
      curve: ClientMotion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final office = widget.office;

    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      body: Stack(
        children: [
          BlocBuilder<OfficeProfileCubit, OfficeProfileState>(
            builder: (context, state) {
              final loaded = state is OfficeProfileLoaded ? state : null;

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<OfficeProfileCubit>().load(office.id),
                // The spinner drops below the floating bar rather than behind it.
                edgeOffset: _chromeHeight,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: OfficeProfileHeader(
                        office: office,
                        stats: loaded == null
                            ? null
                            : OfficeProfileStats(
                                counts: (
                                  departures: loaded.trips.length,
                                  routes: loaded.routes.length,
                                ),
                                onSelect: _scrollToSection,
                              ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        ClientSpacing.md,
                        ClientSpacing.lg,
                        ClientSpacing.md,
                        ClientSpacing.xl,
                      ),
                      sliver: SliverList.list(
                        children: [_body(context, state)],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _barProgress,
              builder: (context, progress, _) =>
                  OfficeProfileTopBar(title: office.name, progress: progress),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, OfficeProfileState state) {
    final l10n = context.l10n;

    return switch (state) {
      OfficeProfileLoading() => const _ProfileSkeleton(),
      OfficeProfileError(:final message) => ClientErrorCard(
        message: message,
        retryLabel: l10n.common_retry,
        onRetry: () =>
            context.read<OfficeProfileCubit>().load(widget.office.id),
      ),
      OfficeProfileLoaded(:final routes, :final trips)
          when routes.isEmpty && trips.isEmpty =>
        const OfficeNothingListedView(),
      OfficeProfileLoaded(:final routes, :final trips) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OfficeProfileSectionBlock(
            key: _departuresKey,
            icon: Icons.departure_board_rounded,
            title: l10n.offices_departuresHeader,
            count: trips.length,
            child: trips.isEmpty
                ? OfficeEmptyNote(
                    icon: Icons.event_busy_rounded,
                    message: l10n.offices_noDepartures,
                  )
                : OfficeDeparturesSection(trips: trips, onOpenTrip: _openTrip),
          ),
          OfficeProfileSectionBlock(
            key: _routesKey,
            icon: Icons.alt_route_rounded,
            title: l10n.offices_routesHeader,
            count: routes.length,
            child: routes.isEmpty
                ? OfficeEmptyNote(
                    icon: Icons.wrong_location_outlined,
                    message: l10n.offices_noRoutes,
                  )
                : OfficeRoutesSection(
                    routes: routes,
                    onOpenRoute: (route) => _openRoute(route.id),
                  ),
          ),
        ],
      ),
    };
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonHeading(width: 180),
        SizedBox(height: ClientSpacing.sm),
        ClientSkeleton(height: 108, borderRadius: ClientRadius.lg),
        SizedBox(height: ClientSpacing.xs),
        ClientSkeleton(height: 108, borderRadius: ClientRadius.lg),
        SizedBox(height: ClientSpacing.lg),
        _SkeletonHeading(width: 130),
        SizedBox(height: ClientSpacing.sm),
        ClientSkeleton(height: 96, borderRadius: ClientRadius.lg),
      ],
    );
  }
}

/// A section title's placeholder — start-aligned so the stretched column does
/// not blow it out to the full width and lose the "this is a heading" shape.
class _SkeletonHeading extends StatelessWidget {
  const _SkeletonHeading({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ClientSkeleton(
        height: 36,
        width: width,
        borderRadius: ClientRadius.sm,
      ),
    );
  }
}
