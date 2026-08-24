import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/selection_picker_sheet.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_state.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_route_search_card.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The hero search card wired to [BookingSearchCubit].
///
/// Home now holds a real pickup/destination selection: the two rows open the
/// station picker in place and the swap disc flips them, so the CTA is the
/// only tap target on the card that leaves the screen. Where it goes is the
/// caller's call — [onSearch] receives the query as it stands.
///
/// Reuses the booking search cubit rather than a Home-only copy, so the
/// station options, the recent-search shortcuts and the swap rule stay one
/// implementation shared with [SearchTripForm].
class HomeHeroSearchForm extends StatelessWidget {
  const HomeHeroSearchForm({super.key, required this.onSearch});

  final void Function(BookingSearchQuery query) onSearch;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingSearchCubit, BookingSearchState>(
      builder: (context, state) => HomeRouteSearchCard(
        pickup: state.query.pickup,
        destination: state.query.destination,
        onPickupTap: () => _pickStation(context, state, isPickup: true),
        onDestinationTap: () => _pickStation(context, state, isPickup: false),
        onSwap: context.read<BookingSearchCubit>().swap,
        onSearch: () => onSearch(state.query),
      ),
    );
  }

  Future<void> _pickStation(
    BuildContext context,
    BookingSearchState state, {
    required bool isPickup,
  }) async {
    final l10n = context.l10n;
    final cubit = context.read<BookingSearchCubit>();
    final title = isPickup
        ? l10n.booking_pickupLocation
        : l10n.booking_destination;
    final current = isPickup ? state.query.pickup : state.query.destination;
    final value = await SelectionPickerSheet.show(
      context: context,
      title: title,
      options: isPickup ? state.pickupOptions : state.destinationOptions,
      selected: current.isEmpty ? null : current,
      recent: isPickup ? state.recentPickups : state.recentDestinations,
      enableSearch: true,
      searchHint: l10n.booking_searchHint(title),
      isLoading: state.optionsLoading,
      errorMessage: state.optionsError,
      onRetry: cubit.loadOptions,
      emptyMessage: isPickup
          ? l10n.booking_noPickupPointsAvailable
          : l10n.booking_noDestinationsAvailable,
    );
    if (value == null || !context.mounted) return;
    isPickup ? cubit.selectPickup(value) : cubit.selectDestination(value);
  }
}
