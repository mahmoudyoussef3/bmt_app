import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/selection_picker_sheet.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/search_date_options.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/search_trip_card.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The pickup/destination/date/time search card plus its selection pickers,
/// driven by [BookingSearchCubit].
class SearchTripForm extends StatelessWidget {
  const SearchTripForm({super.key, required this.state});

  final BookingSearchState state;

  @override
  Widget build(BuildContext context) {
    final query = state.query;
    return SearchTripCard(
      pickup: query.pickup,
      destination: query.destination,
      date: query.date,
      time: query.time,
      onSwap: context.read<BookingSearchCubit>().swap,
      onPickupTap: () => _pickLocation(context, isPickup: true),
      onDestinationTap: () => _pickLocation(context, isPickup: false),
      onDateTap: () => _pickDate(context),
      onTimeTap: () => _pickTime(context),
      onSearch: () => _search(context),
    );
  }

  Future<void> _pickLocation(
    BuildContext context, {
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

  Future<void> _pickDate(BuildContext context) async {
    final value = await SelectionPickerSheet.show(
      context: context,
      title: context.l10n.booking_selectDate,
      options: buildSearchDateOptions(context),
      selected: state.query.date,
    );
    if (value != null && context.mounted) {
      context.read<BookingSearchCubit>().setDate(value);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final value = await SelectionPickerSheet.show(
      context: context,
      title: context.l10n.booking_selectTime,
      options: state.timeOptions,
      selected: state.query.time.isEmpty ? null : state.query.time,
      isLoading: state.optionsLoading,
      errorMessage: state.optionsError,
      onRetry: context.read<BookingSearchCubit>().loadOptions,
      emptyMessage: context.l10n.booking_noDepartureTimesAvailable,
    );
    if (value != null && context.mounted) {
      context.read<BookingSearchCubit>().setTime(value);
    }
  }

  void _search(BuildContext context) {
    final query = state.query;
    if (!query.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.booking_selectPickupDestination)),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      BookingRoutes.mapSelection,
      arguments: query.toArguments(),
    );
  }
}
