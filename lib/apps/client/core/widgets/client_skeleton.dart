import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Shimmer skeleton primitives for the client app.
///
/// Unlike the shared [SkeletonBox] which uses a static fill, [ClientSkeleton]
/// uses a shimmer animation so loading states feel alive.
///
/// Pre-built skeletons for the most common card shapes:
/// - [ClientSkeleton.tripCard] — upcoming/active trip card
/// - [ClientSkeleton.routeCard] — horizontal route discovery card
/// - [ClientSkeleton.packageCard] — subscription package card
/// - [ClientSkeleton.notificationItem] — notification center row
/// - [ClientSkeleton.officeCard] — offices directory list row
class ClientSkeleton extends StatefulWidget {
  const ClientSkeleton({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 12,
  });

  final double height;
  final double? width;
  final double borderRadius;

  /// Skeleton matching a [ClientTripCard] in upcoming/active mode.
  static Widget tripCard() => const _SkeletonTripCard();

  /// Skeleton matching a horizontal route discovery card.
  static Widget routeCard() => const _SkeletonRouteCard();

  /// Skeleton matching a package plan card.
  static Widget packageCard() => const _SkeletonPackageCard();

  /// Skeleton matching a notification center list item.
  static Widget notificationItem() => const _SkeletonNotificationItem();

  /// Skeleton matching an [OfficeCard] row in the offices directory.
  static Widget officeCard() => const _SkeletonOfficeCard();

  @override
  State<ClientSkeleton> createState() => _ClientSkeletonState();
}

class _ClientSkeletonState extends State<ClientSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = ClientColors.surfaceMutedFor(context);
    final highlight = ClientColors.borderFor(context);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [
              (_shimmer.value - 0.3).clamp(0.0, 1.0),
              _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.3).clamp(0.0, 1.0),
            ],
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}

class _SkeletonTripCard extends StatelessWidget {
  const _SkeletonTripCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClientSkeleton(height: 12, width: 80, borderRadius: 6),
              const Spacer(),
              ClientSkeleton(height: 22, width: 70, borderRadius: 11),
            ],
          ),
          const SizedBox(height: 12),
          ClientSkeleton(height: 18, width: 200, borderRadius: 6),
          const SizedBox(height: 6),
          ClientSkeleton(height: 13, width: 140, borderRadius: 6),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ClientSkeleton(height: 36, borderRadius: 10)),
              const SizedBox(width: 10),
              Expanded(child: ClientSkeleton(height: 36, borderRadius: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonRouteCard extends StatelessWidget {
  const _SkeletonRouteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientSkeleton(height: 14, width: 90, borderRadius: 6),
          const SizedBox(height: 6),
          ClientSkeleton(height: 14, width: 110, borderRadius: 6),
          const SizedBox(height: 16),
          ClientSkeleton(height: 12, width: 60, borderRadius: 6),
          const SizedBox(height: 4),
          ClientSkeleton(height: 16, width: 80, borderRadius: 6),
        ],
      ),
    );
  }
}

class _SkeletonPackageCard extends StatelessWidget {
  const _SkeletonPackageCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClientSkeleton(height: 16, width: 130, borderRadius: 6),
              const Spacer(),
              ClientSkeleton(height: 16, width: 60, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 8),
          ClientSkeleton(height: 13, width: 180, borderRadius: 6),
          const SizedBox(height: 16),
          ClientSkeleton(height: 36, borderRadius: 10),
        ],
      ),
    );
  }
}

class _SkeletonNotificationItem extends StatelessWidget {
  const _SkeletonNotificationItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientSkeleton(height: 40, width: 40, borderRadius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClientSkeleton(height: 14, width: 200, borderRadius: 6),
                const SizedBox(height: 6),
                ClientSkeleton(height: 12, width: 140, borderRadius: 6),
                const SizedBox(height: 4),
                ClientSkeleton(height: 10, width: 60, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonOfficeCard extends StatelessWidget {
  const _SkeletonOfficeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClientSkeleton(height: 56, width: 56, borderRadius: 17),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClientSkeleton(height: 15, width: 150),
                          const SizedBox(height: 8),
                          ClientSkeleton(height: 11, width: 190),
                          const SizedBox(height: 6),
                          ClientSkeleton(height: 11, width: 120),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ClientSkeleton(height: 24, width: 46, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClientSkeleton(height: 22, width: 62, borderRadius: 8),
                    const SizedBox(width: 6),
                    ClientSkeleton(height: 22, width: 54, borderRadius: 8),
                    const SizedBox(width: 6),
                    ClientSkeleton(height: 22, width: 70, borderRadius: 8),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 37,
            decoration: BoxDecoration(
              color: ClientColors.surfaceSubtleFor(context),
              border: Border(
                top: BorderSide(color: ClientColors.borderFor(context)),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(23),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
