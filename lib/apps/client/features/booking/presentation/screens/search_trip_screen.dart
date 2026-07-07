import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/storage/recent_search_store.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/core/widgets/selection_picker_sheet.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/search_trip_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/search_options.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/search_date_options.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/search_option_tile.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

const _recentPickupsKey = 'booking_recent_pickups';
const _recentDestinationsKey = 'booking_recent_destinations';

class SearchTripScreen extends StatefulWidget {
  const SearchTripScreen({super.key, this.initialQuery});

  final BookingSearchQuery? initialQuery;

  @override
  State<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends State<SearchTripScreen> {
  static const _recentStore = RecentSearchStore();

  late BookingSearchQuery _query;
  TripSearchOptions? _options;
  bool _optionsLoading = true;
  String? _optionsError;
  List<String> _recentPickups = const [];
  List<String> _recentDestinations = const [];

  @override
  void initState() {
    super.initState();
    _query = (widget.initialQuery ?? const BookingSearchQuery()).copyWith(
      date: widget.initialQuery?.date.isNotEmpty == true
          ? widget.initialQuery!.date
          : todaySearchDateLabel(),
    );
    final cubit = context.read<BookingCubit>();
    final currentState = cubit.state;
    if (currentState is SearchOptionsLoaded) {
      _options = currentState.options;
      _optionsLoading = false;
    } else {
      cubit.loadSearchOptions();
    }
    _recentStore.get(_recentPickupsKey).then((value) {
      if (mounted) setState(() => _recentPickups = value);
    });
    _recentStore.get(_recentDestinationsKey).then((value) {
      if (mounted) setState(() => _recentDestinations = value);
    });
  }

  List<String> get _pickupOptions => _options?.pickupPoints ?? [];
  List<String> get _destinationOptions => _options?.destinations ?? [];
  List<String> get _timeOptions => _options?.departureTimes ?? [];
  List<String> get _dateOptions => buildSearchDateOptions();

  void _retryLoadOptions() {
    setState(() {
      _optionsLoading = true;
      _optionsError = null;
    });
    context.read<BookingCubit>().loadSearchOptions(force: true);
  }

  Future<void> _pickLocation({
    required String title,
    required List<String> options,
    required String field,
    required String emptyMessage,
  }) async {
    final isPickup = field == 'pickup';
    final current = isPickup ? _query.pickup : _query.destination;
    final recentKey = isPickup ? _recentPickupsKey : _recentDestinationsKey;
    final recent = isPickup ? _recentPickups : _recentDestinations;
    final value = await SelectionPickerSheet.show(
      context: context,
      title: title,
      options: options,
      selected: current.isEmpty ? null : current,
      recent: recent,
      enableSearch: true,
      searchHint: 'Search $title',
      isLoading: _optionsLoading,
      errorMessage: _optionsError,
      onRetry: _retryLoadOptions,
      emptyMessage: emptyMessage,
    );
    if (value == null) return;
    setState(() {
      _query = isPickup
          ? _query.copyWith(pickup: value)
          : _query.copyWith(destination: value);
    });
    await _recentStore.add(recentKey, value);
    final updatedRecent = [value, ...recent.where((r) => r != value)];
    setState(() {
      if (isPickup) {
        _recentPickups = updatedRecent.take(5).toList();
      } else {
        _recentDestinations = updatedRecent.take(5).toList();
      }
    });
  }

  void _swapPickupAndDestination() {
    setState(() {
      _query = _query.copyWith(
        pickup: _query.destination,
        destination: _query.pickup,
      );
    });
  }

  void _search() {
    if (!_query.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.booking_selectPickupDestination,
          ),
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      BookingRoutes.mapSelection,
      arguments: _query.toArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingCubit, BookingState>(
      listener: (context, state) {
        if (_options != null) return;
        if (state is SearchOptionsLoaded) {
          setState(() {
            _options = state.options;
            _optionsLoading = false;
            _optionsError = null;
          });
        } else if (state is BookingLoading) {
          setState(() => _optionsLoading = true);
        } else if (state is BookingError) {
          setState(() {
            _optionsLoading = false;
            _optionsError = state.message;
          });
        }
      },
      child: BookingFlowScaffold(
        title: AppLocalizations.of(context)!.booking_searchTrip,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SearchTripCard(
              pickup: _query.pickup,
              destination: _query.destination,
              date: _query.date,
              time: _query.time,
              onSwap: _swapPickupAndDestination,
              onPickupTap: () => _pickLocation(
                title: AppLocalizations.of(context)!.booking_pickupLocation,
                options: _pickupOptions,
                field: 'pickup',
                emptyMessage:
                    'No pickup points available yet. Please check back soon.',
              ),
              onDestinationTap: () => _pickLocation(
                title: AppLocalizations.of(context)!.booking_destination,
                options: _destinationOptions,
                field: 'destination',
                emptyMessage: 'No destinations available yet.',
              ),
              onDateTap: () async {
                final value = await SelectionPickerSheet.show(
                  context: context,
                  title: AppLocalizations.of(context)!.booking_selectDate,
                  options: _dateOptions,
                  selected: _query.date,
                );
                if (value != null) {
                  setState(() => _query = _query.copyWith(date: value));
                }
              },
              onTimeTap: () async {
                final value = await SelectionPickerSheet.show(
                  context: context,
                  title: AppLocalizations.of(context)!.booking_selectTime,
                  options: _timeOptions,
                  selected: _query.time.isEmpty ? null : _query.time,
                  isLoading: _optionsLoading,
                  errorMessage: _optionsError,
                  onRetry: _retryLoadOptions,
                  emptyMessage:
                      'No departure times available for this route yet.',
                );
                if (value != null) {
                  setState(() => _query = _query.copyWith(time: value));
                }
              },
              onSearch: _search,
            ),
            const SizedBox(height: 20),
            ClientSectionHeader(
              title: AppLocalizations.of(context)!.booking_otherWaysToSearch,
              subtitle: AppLocalizations.of(context)!.booking_browseOrPickMap,
            ),
            const SizedBox(height: 12),
            SearchOptionTile(
              icon: Icons.trending_up_rounded,
              iconColor: ClientColors.primary,
              title: AppLocalizations.of(context)!.booking_popularRoutes,
              subtitle: AppLocalizations.of(
                context,
              )!.booking_popularRoutesSubtitle,
              onTap: () => Navigator.pushNamed(
                context,
                BookingRoutes.popularRoutes,
                arguments: _query.toArguments(),
              ),
            ),
            const SizedBox(height: 10),
            /*    _SearchOptionTile(
              icon: Icons.map_rounded,
              iconColor: ClientColors.journeySlate,
              title: AppLocalizations.of(context)!.booking_selectOnMap,
              subtitle:
                  AppLocalizations.of(context)!.booking_selectOnMapSubtitle,
              onTap: () => Navigator.pushNamed(
                context,
                BookingRoutes.mapSelection,
                arguments: _query.toArguments(),
              ),
              
            ),
            */
          ],
        ),
      ),
    );
  }
}
