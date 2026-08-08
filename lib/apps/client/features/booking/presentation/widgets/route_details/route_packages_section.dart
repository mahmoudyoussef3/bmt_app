import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_packages_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_packages_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_packages_panel.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';

/// The commute plans the route's operator sells, priced against this corridor.
///
/// This is where packages live now. On the office profile they could only ever
/// say "priced later", because a plan has no price until a route prices it —
/// here the route exists, so every plan carries a real "from" figure and a tap
/// starts the booking with that plan already chosen.
///
/// It asks for its own data: Route Details only learns whose route it is
/// showing once the results land, so the office id arrives with this widget
/// rather than at the route's construction. Anything but a loaded, non-empty
/// catalogue renders nothing — a shelf of plans is optional context beside a
/// route the rider can already book.
class RoutePackagesSection extends StatefulWidget {
  const RoutePackagesSection({
    super.key,
    required this.route,
    required this.onSelectPackage,
  });

  final RouteOptionData route;
  final ValueChanged<PackagePlan> onSelectPackage;

  @override
  State<RoutePackagesSection> createState() => _RoutePackagesSectionState();
}

class _RoutePackagesSectionState extends State<RoutePackagesSection> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RoutePackagesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.office.id != widget.route.office.id) _load();
  }

  void _load() =>
      context.read<RoutePackagesCubit>().loadFor(widget.route.office.id);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutePackagesCubit, RoutePackagesState>(
      builder: (context, state) {
        if (state is! RoutePackagesLoaded || state.packages.isEmpty) {
          return const SizedBox.shrink();
        }
        // The leading gap belongs to the section, not to the list above it, so
        // a route with no plans leaves no stray space behind.
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: RoutePackagesPanel(
            route: widget.route,
            packages: state.packages,
            onSelect: widget.onSelectPackage,
          ),
        );
      },
    );
  }
}
