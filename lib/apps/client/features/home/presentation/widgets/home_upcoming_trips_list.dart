import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trip_card.dart';

/// The departure board on Home: every trip a rider can take a seat on, soonest
/// first, as a horizontal rail of boarding passes.
///
/// A rail rather than a stack: the board carries up to fifty departures, and a
/// rider deciding between them wants the next one whole and in front of them,
/// not a page of half-cards. It snaps card by card so a departure is never left
/// hanging off the edge, every card peeks the one behind it so the rail reads
/// as continuable, and a progress rule under it says how much board is left.
/// The rail ends on a card into the full route list, so the departures that
/// scrolled past the edge are always one tap away.
class HomeUpcomingTripsList extends StatefulWidget {
  const HomeUpcomingTripsList({
    super.key,
    required this.trips,
    required this.onBook,
    required this.onBrowseRoutes,
  });

  final List<UpcomingTripData> trips;
  final ValueChanged<UpcomingTripData> onBook;
  final VoidCallback onBrowseRoutes;

  @override
  State<HomeUpcomingTripsList> createState() => _HomeUpcomingTripsListState();
}

class _HomeUpcomingTripsListState extends State<HomeUpcomingTripsList> {
  final ScrollController _controller = ScrollController();

  /// Widest a card is allowed to get. Past this the ticket stops reading as a
  /// card in a rail and starts reading as a panel that happens to scroll.
  static const double _maxCardWidth = 320;

  /// How much of the rail one card takes. The remainder is the peek of the
  /// next departure — the whole reason a rider knows to swipe.
  static const double _cardWidthFactor = 0.86;

  static const double _gap = ClientSpacing.md;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trips.isEmpty) {
      return SliverToBoxAdapter(
        child: _NoDepartures(onBrowseRoutes: widget.onBrowseRoutes),
      );
    }

    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = math.min(
            constraints.maxWidth * _cardWidthFactor,
            _maxCardWidth,
          );
          final extent = cardWidth + _gap;
          final railHeight = HomeUpcomingTripCard.heightFor(
            context,
            anyBooked: widget.trips.any((trip) => trip.isBooked),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: railHeight,
                child: ListView.builder(
                  // A new key when the card step changes (rotation, a resized
                  // window) rebuilds the scrollable so the snap physics below
                  // can never be left snapping to a stale extent.
                  key: ValueKey<double>(extent),
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  itemExtent: extent,
                  physics: _CardSnapPhysics(itemExtent: extent),
                  itemCount: widget.trips.length + 1,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: _gap),
                      child: index == widget.trips.length
                          ? _BrowseAllCard(onTap: widget.onBrowseRoutes)
                          : HomeUpcomingTripCard(
                              trip: widget.trips[index],
                              onBook: () => widget.onBook(widget.trips[index]),
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: ClientSpacing.md),
              _RailProgress(controller: _controller),
            ],
          );
        },
      ),
    );
  }
}

/// Snaps the rail to whole cards.
///
/// It lets the underlying platform physics decide *where* a fling lands — so a
/// hard swipe still crosses several departures — and only rounds that landing
/// to the nearest card, which is what stops a rider from being handed two half
/// tickets to compare.
class _CardSnapPhysics extends ScrollPhysics {
  const _CardSnapPhysics({required this.itemExtent, super.parent});

  /// One card plus the gap after it — the rail's whole scroll step.
  final double itemExtent;

  @override
  _CardSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _CardSnapPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final ballistic = super.createBallisticSimulation(position, velocity);

    // At either end there is nothing to snap to; let the platform run its
    // overscroll/settle simulation untouched.
    if (itemExtent <= 0 ||
        (velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return ballistic;
    }

    final landing = ballistic?.x(double.infinity) ?? position.pixels;
    final settled = landing.isFinite ? landing : position.pixels;
    final target = ((settled / itemExtent).roundToDouble() * itemExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    final tolerance = toleranceFor(position);
    if ((target - position.pixels).abs() < tolerance.distance) return null;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// A slim rule that says how much of the departure board is still to the side.
///
/// Dots would lie on a board of fifty departures; a proportional thumb tells
/// the truth at any length, and it reads as a scroll rule rather than as a
/// control, which is what it is.
class _RailProgress extends StatefulWidget {
  const _RailProgress({required this.controller});

  final ScrollController controller;

  static const double _trackWidth = 72;
  static const double _height = 4;

  @override
  State<_RailProgress> createState() => _RailProgressState();
}

class _RailProgressState extends State<_RailProgress> {
  @override
  void initState() {
    super.initState();
    // The controller has no position until the rail has been laid out once,
    // so the first honest reading of it is a frame away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final track = _track(context);
        return SizedBox(
          height: _RailProgress._height,
          child: Center(child: track),
        );
      },
    );
  }

  Widget _track(BuildContext context) {
    if (!widget.controller.hasClients) return const SizedBox.shrink();

    final position = widget.controller.position;
    // Every one of these is a `!` on a nullable field inside the metrics: the
    // rail is asked to draw itself on the frame before it has been measured.
    if (!position.hasPixels ||
        !position.hasContentDimensions ||
        !position.hasViewportDimension) {
      return const SizedBox.shrink();
    }

    final maxScroll = position.maxScrollExtent;
    if (maxScroll <= 0) return const SizedBox.shrink();

    final visible =
        position.viewportDimension / (position.viewportDimension + maxScroll);
    final progress = (position.pixels / maxScroll).clamp(0.0, 1.0);
    final thumbWidth = math.max(14.0, _RailProgress._trackWidth * visible);

    return Container(
      width: _RailProgress._trackWidth,
      height: _RailProgress._height,
      decoration: BoxDecoration(
        color: ClientColors.borderFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Align(
        // Directional so the thumb travels with the reading direction: in
        // Arabic the rail scrolls right-to-left and so must its rule.
        alignment: AlignmentDirectional(-1 + 2 * progress, 0),
        child: Container(
          width: thumbWidth,
          height: _RailProgress._height,
          decoration: BoxDecoration(
            color: ClientColors.primaryFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.pill),
          ),
        ),
      ),
    );
  }
}

/// The card the rail ends on: what a rider does when none of the departures in
/// front of them is the one they wanted. A rail hides everything past its edge,
/// so it has to hand back the way to the whole list.
class _BrowseAllCard extends StatelessWidget {
  const _BrowseAllCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(ClientSpacing.lg),
        decoration: BoxDecoration(
          // The rail's own surface, so the end-cap reads as the last card in
          // the deck; no shadow, because it is a door, not a departure.
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.lg),
          border: Border.all(color: primary.withAlpha(60)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primary.withAlpha(28),
                shape: BoxShape.circle,
              ),
              child: DirectionalIcon(
                Icons.arrow_forward_rounded,
                size: 26,
                color: primary,
              ),
            ),
            const SizedBox(height: ClientSpacing.md),
            Text(
              context.l10n.home_allRoutes,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.headingSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single quiet row rather than a panel: the departure board's header
/// already announces the section and offers "all routes", so an empty board
/// only has to say it is empty and stay out of the way of the sections under
/// it. The whole row is the tap target into the route list.
class _NoDepartures extends StatelessWidget {
  const _NoDepartures({required this.onBrowseRoutes});

  final VoidCallback onBrowseRoutes;

  @override
  Widget build(BuildContext context) {
    final muted = ClientColors.textSecondaryFor(context);

    return PressableScale(
      onTap: onBrowseRoutes,
      scale: 0.99,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: ClientSpacing.md,
          vertical: ClientSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.md),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy_rounded, size: 20, color: muted),
            const SizedBox(width: ClientSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.home_noDepartures,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(color: muted),
              ),
            ),
            const SizedBox(width: ClientSpacing.sm),
            Text(
              context.l10n.home_browseRoutes,
              style: ClientTypography.labelMedium(context).copyWith(
                color: ClientColors.primaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: ClientSpacing.xxs),
            DirectionalIcon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: ClientColors.primaryFor(context),
            ),
          ],
        ),
      ),
    );
  }
}
