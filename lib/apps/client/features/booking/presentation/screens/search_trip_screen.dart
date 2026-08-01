import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/search_option_tile.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/search_trip_form.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Trip-search entry screen: pick pickup/destination/date/time then search,
/// or browse popular routes.
class SearchTripScreen extends StatelessWidget {
  const SearchTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingSearchCubit, BookingSearchState>(
      builder: (context, state) {
        return BookingFlowScaffold(
          title: context.l10n.booking_searchTrip,
          actions: [
            IconButton(
              tooltip: context.l10n.tracking_refresh,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: context.read<BookingSearchCubit>().loadOptions,
            ),
          ],
          body: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                SearchTripForm(state: state),
                const SizedBox(height: 20),
                ClientSectionHeader(
                  title: context.l10n.booking_otherWaysToSearch,
                  subtitle: context.l10n.booking_browseOrPickMap,
                ),
                const SizedBox(height: 12),
                SearchOptionTile(
                  icon: Icons.trending_up_rounded,
                  iconColor: ClientColors.primary,
                  title: context.l10n.booking_popularRoutes,
                  subtitle: context.l10n.booking_popularRoutesSubtitle,
                  onTap: () => Navigator.pushNamed(
                    context,
                    BookingRoutes.popularRoutes,
                    arguments: state.query.toArguments(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
