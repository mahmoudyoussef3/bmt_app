import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/modules/home/home/presentation/widgets/search_trip_card.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/search_options.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Generates the next [count] selectable dates as display strings.
List<String> _buildDateOptions({int count = 7}) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final now = DateTime.now();
  return List.generate(count, (i) {
    final d = now.add(Duration(days: i));
    final month = months[d.month - 1];
    final day = d.day;
    if (i == 0) return 'Today, $month $day';
    if (i == 1) return 'Tomorrow, $month $day';
    return '${weekdays[d.weekday - 1]}, $month $day';
  });
}

String _todayLabel() => _buildDateOptions(count: 1).first;

class SearchTripScreen extends StatefulWidget {
  const SearchTripScreen({super.key, this.initialQuery});

  final BookingSearchQuery? initialQuery;

  @override
  State<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends State<SearchTripScreen> {
  late BookingSearchQuery _query;
  TripSearchOptions? _options;

  @override
  void initState() {
    super.initState();
    _query = (widget.initialQuery ?? const BookingSearchQuery()).copyWith(
      date: widget.initialQuery?.date.isNotEmpty == true
          ? widget.initialQuery!.date
          : _todayLabel(),
    );
    context.read<BookingCubit>().loadSearchOptions();
  }

  List<String> get _pickupOptions => _options?.pickupPoints ?? [];
  List<String> get _destinationOptions => _options?.destinations ?? [];
  List<String> get _timeOptions => _options?.departureTimes ?? [];
  List<String> get _dateOptions => _buildDateOptions();

  Future<void> _pickLocation({
    required String title,
    required List<String> options,
    required String field,
  }) async {
    final current = field == 'pickup' ? _query.pickup : _query.destination;
    final value = await showHomePickerSheet(
      context: context,
      title: title,
      options: options,
      selected: current.isEmpty ? null : current,
    );
    if (value == null) return;
    setState(() {
      _query = field == 'pickup'
          ? _query.copyWith(pickup: value)
          : _query.copyWith(destination: value);
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
      ClientRoutes.bookingRouteSelection,
      arguments: _query.toArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state is SearchOptionsLoaded) {
          setState(() => _options = state.options);
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
              onPickupTap: () => _pickLocation(
                title: AppLocalizations.of(context)!.booking_pickupLocation,
                options: _pickupOptions,
                field: 'pickup',
              ),
              onDestinationTap: () => _pickLocation(
                title: AppLocalizations.of(context)!.booking_destination,
                options: _destinationOptions,
                field: 'destination',
              ),
              onDateTap: () async {
                final value = await showHomePickerSheet(
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
                final value = await showHomePickerSheet(
                  context: context,
                  title: AppLocalizations.of(context)!.booking_selectTime,
                  options: _timeOptions,
                  selected: _query.time.isEmpty ? null : _query.time,
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
            _SearchOptionTile(
              icon: Icons.trending_up_rounded,
              iconColor: ClientColors.primary,
              title: AppLocalizations.of(context)!.booking_popularRoutes,
              subtitle: AppLocalizations.of(
                context,
              )!.booking_popularRoutesSubtitle,
              onTap: () => Navigator.pushNamed(
                context,
                ClientRoutes.bookingPopularRoutes,
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
                ClientRoutes.bookingMapSelection,
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

class _SearchOptionTile extends StatelessWidget {
  const _SearchOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: ClientColors.borderFor(context)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      ),
    );
  }
}
