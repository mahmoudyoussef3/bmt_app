import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_eta_panel.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_live_map.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_stops_timeline.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

typedef TripState = TrackingTripState;

class TrackingScreen extends StatefulWidget {
  final bool shellMode;
  final String? bookingId;
  final String? tripId;

  const TrackingScreen({
    super.key,
    this.shellMode = false,
    this.bookingId,
    this.tripId,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  TrackingLoaded? _tracking;

  TripState get _currentState =>
      _tracking?.currentState ?? TripState.notStarted;

  String get _stateTitle => _tracking?.title ?? 'Trip Status';

  int get _driverRating => _tracking?.ratings.driver ?? 0;

  int get _vehicleRating => _tracking?.ratings.vehicle ?? 0;

  int get _routeRating => _tracking?.ratings.route ?? 0;

  TrackingTripData? get _trip => _tracking?.data;

  String get _routeName => _trip?.routeName ?? 'Trip route';

  String get _pickupName {
    final trip = _trip;
    return trip?.pickupName ??
        (trip?.stops.isNotEmpty == true ? trip!.stops.first : 'Pickup');
  }

  String get _destinationName {
    final trip = _trip;
    return trip?.destinationName ??
        (trip?.stops.isNotEmpty == true ? trip!.stops.last : 'Destination');
  }

  int get _currentTimelineStep {
    return switch (_currentState) {
      TripState.notStarted => 1,
      TripState.driverOnWay => 2,
      TripState.boarding => 3,
      TripState.inProgress => 4,
      TripState.completed => 5,
    };
  }

  RouteProgressSnapshot? get _progress => _tracking?.progress;

  String _formatTime(DateTime? value) {
    if (value == null) return 'Pending';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatRelativeDeparture() {
    final departure = _trip?.departureAt;
    if (departure == null) return 'Scheduled time pending';
    final diff = departure.difference(DateTime.now());
    if (diff.inMinutes > 0) {
      return 'Trip starts in ${diff.inMinutes} minutes';
    }
    if (diff.inMinutes > -5) return 'Trip is starting now';
    return 'Scheduled trip';
  }

  String _liveLocationLabel() {
    final updatedAt = _trip?.vehicleLocationAt;
    if (updatedAt == null) return 'Waiting for driver location';
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'Location sent just now';
    return 'Location sent ${diff.inMinutes} min ago';
  }

  @override
  void initState() {
    super.initState();
    context.read<TrackingCubit>().load(
      bookingId: widget.bookingId,
      tripId: widget.tripId,
    );
  }

  void _changeState(TripState state) {
    context.read<TrackingCubit>().changeState(state);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;

    return BlocBuilder<TrackingCubit, TrackingState>(
      builder: (context, state) {
        if (state is TrackingLoading) {
          return Scaffold(
            backgroundColor: ClientColors.surfaceMutedFor(context),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is TrackingError) {
          return Scaffold(
            backgroundColor: ClientColors.surfaceMutedFor(context),
            body: ClientErrorCard.fullScreen(message: state.message),
          );
        }

        final loaded = state as TrackingLoaded;
        _tracking = loaded;

        final isActive = _currentState != TripState.notStarted;

        return Scaffold(
          extendBodyBehindAppBar: isActive,
          backgroundColor: isActive
              ? scheme.surface
              : ClientColors.surfaceMutedFor(context),
          appBar: AppBar(
            title: Text(
              _stateTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              if (widget.shellMode)
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Preview trip states',
                  onPressed: () => _showStatePreviewSheet(context, scheme),
                ),
            ],
            elevation: 0,
            backgroundColor: isActive
                ? Colors.transparent
                : ClientColors.surfaceFor(context),
          ),
          body: Stack(
            children: [
              // Background subtle gradients
              Positioned(
                top: -100,
                right: -100,
                child: _BackgroundGlow(
                  color: ClientColors.primary.withAlpha(20),
                  size: 300,
                ),
              ),
              Positioned(
                bottom: -50,
                left: -100,
                child: _BackgroundGlow(
                  color: ClientColors.journeyGreen.withAlpha(15),
                  size: 250,
                ),
              ),

              // Main Layout Content
              Positioned.fill(
                child: isTablet
                    ? _buildTabletLayout(context, scheme)
                    : _buildMobileLayout(context, scheme),
              ),

              if (loaded.isRefreshing)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: ClientColors.primary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showStatePreviewSheet(BuildContext context, ColorScheme scheme) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Preview trip state',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStateTab('Waiting', TripState.notStarted, scheme),
                    _buildStateTab('Heading', TripState.driverOnWay, scheme),
                    _buildStateTab('Boarding', TripState.boarding, scheme),
                    _buildStateTab('In route', TripState.inProgress, scheme),
                    _buildStateTab('Done', TripState.completed, scheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout(BuildContext context, ColorScheme scheme) {
    if (_currentState == TripState.notStarted) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, widget.shellMode ? 16 : 84, 16, 24),
        children: [
          _buildCountdownCard(context, scheme),
          const SizedBox(height: 16),
          _buildQuickActions(context, scheme),
          const SizedBox(height: 20),
          _buildSectionTitle('Trip Status Timeline', Icons.linear_scale),
          _buildStatusTimeline(context, scheme),
          const SizedBox(height: 20),
          _buildSectionTitle('Trip Details', Icons.info_outline),
          _buildRouteInfoCard(context, scheme),
          const SizedBox(height: 16),
          _buildVehicleInfoCard(context, scheme),
          const SizedBox(height: 16),
          _buildDriverInfoCard(context, scheme),
        ],
      );
    }

    // Active tracking states: Full-screen map, driver info overlay
    return Stack(
      children: [
        Positioned.fill(child: _buildMapArea(scheme)),
        DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(top: 16, bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withAlpha(50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    _buildActiveStateDetails(context, scheme),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- TABLET/DESKTOP LAYOUT ---
  Widget _buildTabletLayout(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 84.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Map or Countdown Card depending on state
          Expanded(
            flex: 5,
            child: _currentState == TripState.notStarted
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCountdownCard(context, scheme),
                        const SizedBox(height: 20),
                        _buildRouteInfoCard(context, scheme),
                        const SizedBox(height: 20),
                        _buildQuickActions(context, scheme),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 12, 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _buildMapArea(scheme),
                    ),
                  ),
          ),
          // Right side: Active sheet, driver info, and timeline
          Expanded(
            flex: 4,
            child: _currentState == TripState.notStarted
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle(
                          'Trip Status Timeline',
                          Icons.linear_scale,
                        ),
                        _buildStatusTimeline(context, scheme),
                        const SizedBox(height: 24),
                        _buildDriverInfoCard(context, scheme),
                        const SizedBox(height: 16),
                        _buildVehicleInfoCard(context, scheme),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 24, 24),
                    decoration: BoxDecoration(
                      color: ClientColors.surfaceFor(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: ClientColors.borderFor(context),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _buildActiveStateDetails(context, scheme),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- MAP COMPONENT ---
  Widget _buildMapArea(ColorScheme scheme) {
    return TrackingLiveMap(
      routePoints: _trip?.routePoints ?? const <TrackingPoint>[],
      vehicleFix: _trip?.vehicleFix,
      currentState: _currentState,
      progress: _progress,
      onRefresh: () => context.read<TrackingCubit>().refresh(),
    );
  }

  Widget _buildStateTab(String label, TripState state, ColorScheme scheme) {
    final isSelected = _currentState == state;
    return GestureDetector(
      onTap: () => _changeState(state),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? ClientColors.primary
              : ClientColors.surfaceMutedFor(context).withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ClientColors.primary
                : ClientColors.borderFor(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : ClientColors.textSecondaryFor(context),
          ),
        ),
      ),
    );
  }

  // --- SCREEN 1 COMPONENTS ---

  // Countdown Card
  Widget _buildCountdownCard(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ClientColors.primary.withAlpha(45),
            ClientColors.journeyGreen.withAlpha(25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ClientColors.primary.withAlpha(90),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withAlpha(30),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulseIndicator(ClientColors.primary),
              const SizedBox(width: 8),
              Text(
                'UPCOMING RIDE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: ClientColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatRelativeDeparture(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scheduled departure at ${_formatTime(_trip?.departureAt)}',
            style: TextStyle(
              fontSize: 13,
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context).withAlpha(180),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 16,
                  color: ClientColors.journeyGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  _trip?.hasLiveVehicleLocation == true
                      ? _liveLocationLabel()
                      : 'Waiting for the captain to send a location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.journeyGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Actions Card
  Widget _buildQuickActions(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionItem(
            Icons.map_outlined,
            'View Route',
            ClientColors.primary,
            () {
              context.read<TrackingCubit>().refresh();
            },
          ),
          _buildQuickActionItem(
            Icons.chat_bubble_outline_rounded,
            'Contact Driver',
            ClientColors.journeyGreen,
            () {
              _showContactInfo(context, 'Driver', _trip?.driverPhone);
            },
          ),
          _buildQuickActionItem(
            Icons.support_agent_rounded,
            'Support',
            scheme.tertiary,
            () {
              Navigator.of(context).pushNamed('/support');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(50)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Trip Timeline Component
  Widget _buildStatusTimeline(BuildContext context, ColorScheme scheme) {
    final timelineSteps = [
      'Booking Confirmed',
      'Driver Assigned',
      'Driver Heading To Pickup',
      'Boarding Started',
      'Trip Started',
      'Trip Completed',
    ];

    final currentActiveStep = _currentTimelineStep;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: List.generate(timelineSteps.length, (index) {
          final isCompleted = index < currentActiveStep;
          final isActive = index == currentActiveStep;
          final isRemaining = index > currentActiveStep;

          Color stepColor;
          if (isCompleted) {
            stepColor = ClientColors.journeyGreen;
          } else if (isActive) {
            stepColor = ClientColors.primary;
          } else {
            stepColor = ClientColors.borderFor(context);
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? stepColor.withAlpha(40)
                            : isCompleted
                            ? stepColor
                            : Colors.transparent,
                        border: Border.all(
                          color: stepColor,
                          width: isActive ? 5 : 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                size: 10,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    if (index < timelineSteps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted
                              ? ClientColors.journeyGreen
                              : ClientColors.borderFor(context),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timelineSteps[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isActive
                                ? ClientColors.primary
                                : isRemaining
                                ? ClientColors.textSecondaryFor(context)
                                : ClientColors.textPrimaryFor(context),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 4),
                          Text(
                            _timelineDescription(index),
                            style: TextStyle(
                              fontSize: 11,
                              color: ClientColors.textSecondaryFor(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _timelineDescription(int index) {
    return switch (index) {
      1 => '${_trip?.displayDriverName ?? 'Driver'} is assigned to your trip.',
      2 =>
        _trip?.hasLiveVehicleLocation == true
            ? 'Vehicle location is updating from the captain app.'
            : 'Waiting for captain location sharing.',
      3 => 'Vehicle is at pickup or boarding is open.',
      4 => 'Trip is live on the route.',
      5 => 'Trip has arrived.',
      _ => 'Booking is confirmed.',
    };
  }

  // Route Info
  Widget _buildRouteInfoCard(BuildContext context, ColorScheme scheme) {
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
              Icon(
                Icons.directions_bus_rounded,
                color: ClientColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _routeName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildMapTimelineRow(
            Icons.trip_origin_rounded,
            ClientColors.journeyGreen,
            'Pickup Location',
            _pickupName,
            'Scheduled departure: ${_formatTime(_trip?.departureAt)}',
          ),
          _buildLineConnector(context),
          _buildMapTimelineRow(
            Icons.location_on_rounded,
            scheme.tertiary,
            'Destination',
            _destinationName,
            'Expected arrival: ${_formatTime(_trip?.arrivalAt)}',
          ),
        ],
      ),
    );
  }

  Widget _buildMapTimelineRow(
    IconData icon,
    Color color,
    String type,
    String location,
    String timeInfo,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeInfo,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineConnector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Container(
        width: 2,
        height: 24,
        color: ClientColors.borderFor(context),
      ),
    );
  }

  // Vehicle Info
  Widget _buildVehicleInfoCard(BuildContext context, ColorScheme scheme) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _trip?.vehicleType ?? 'Vehicle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ClientColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClientColors.borderFor(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _trip?.displayVehiclePlate ?? 'Plate pending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _trip?.displayVehicleName ?? 'Assigned vehicle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFeatureIconBadge(
                Icons.location_searching_rounded,
                _liveLocationLabel(),
                context,
              ),
              const SizedBox(width: 8),
              if (_trip?.vehicleSpeedKmh != null)
                _buildFeatureIconBadge(
                  Icons.speed_rounded,
                  '${_trip!.vehicleSpeedKmh!.round()} km/h',
                  context,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIconBadge(
    IconData icon,
    String label,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context).withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ClientColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Driver Info
  Widget _buildDriverInfoCard(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ClientColors.primaryLight,
            child: Text(
              _trip?.driverInitials ?? 'DR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ClientColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _trip?.displayDriverName ?? 'Driver assigned',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      _trip?.driverRating?.toStringAsFixed(1) ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.textPrimaryFor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.phone_in_talk_rounded,
              color: ClientColors.primary,
            ),
            onPressed: () =>
                _showContactInfo(context, 'Driver', _trip?.driverPhone),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 2 COMPONENTS ---

  // Live Bottom details widget containing status description, buttons, cards, etc.
  Widget _buildActiveStateDetails(BuildContext context, ColorScheme scheme) {
    Widget stateContent;

    switch (_currentState) {
      case TripState.driverOnWay:
        stateContent = _buildDriverOnWayView(context, scheme);
        break;
      case TripState.boarding:
        stateContent = _buildBoardingView(context, scheme);
        break;
      case TripState.inProgress:
        stateContent = _buildInProgressView(context, scheme);
        break;
      case TripState.completed:
        stateContent = _buildCompletedView(context, scheme);
        break;
      default:
        stateContent = const SizedBox.shrink();
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _buildSheetStatusIndicator(context, scheme),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: stateContent,
        ),
      ],
    );
  }

  Widget _buildSheetStatusIndicator(BuildContext context, ColorScheme scheme) {
    String title = '';
    String subtitle = '';
    Color toneColor = ClientColors.primary;

    switch (_currentState) {
      case TripState.driverOnWay:
        title = 'Driver On The Way';
        subtitle = _trip?.hasLiveVehicleLocation == true
            ? '${_trip?.displayDriverName ?? 'Captain'} is heading towards $_pickupName'
            : 'Waiting for the captain to send a location';
        toneColor = ClientColors.journeyGreen;
        break;
      case TripState.boarding:
        title = 'Boarding Started';
        subtitle = 'Vehicle is at $_pickupName. Board when instructed.';
        toneColor = ClientColors.primary;
        break;
      case TripState.inProgress:
        title = 'Trip In Progress';
        subtitle = 'Heading to $_destinationName';
        toneColor = ClientColors.primary;
        break;
      case TripState.completed:
        title = 'Arrived Safely';
        subtitle = 'Trip completed at ${_formatTime(_trip?.arrivalAt)}';
        toneColor = ClientColors.journeyGreen;
        break;
      default:
        break;
    }

    return Row(
      children: [
        _buildPulseIndicator(toneColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(160),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STATE 2: Driver on the way UI
  Widget _buildDriverOnWayView(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackingEtaPanel(
          progress: _progress,
          riderPickupName: _trip?.passengerPickupName ?? _pickupName,
          riderBoarded: _trip?.passengerBoarded ?? false,
          fallbackArrival: _trip?.departureAt,
        ),
        const SizedBox(height: 16),
        _buildDriverActionCard(context, scheme),
        const SizedBox(height: 16),
        _buildVehicleInfoCard(context, scheme),
      ],
    );
  }

  // STATE 3: Boarding started UI
  Widget _buildBoardingView(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackingEtaPanel(
          progress: _progress,
          riderPickupName: _trip?.passengerPickupName ?? _pickupName,
          riderBoarded: _trip?.passengerBoarded ?? false,
          fallbackArrival: _trip?.departureAt,
        ),
        const SizedBox(height: 16),
        // Boarding instructions & OTP Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ClientColors.primary.withAlpha(50)),
          ),
          child: Column(
            children: [
              const Text(
                'Boarding is open for this confirmed booking',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _trip?.bookingId == null
                      ? 'Booking reference pending'
                      : 'Booking: ${_trip!.bookingId}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: ClientColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDriverActionCard(context, scheme),
      ],
    );
  }

  // STATE 4: Trip in progress UI
  Widget _buildInProgressView(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackingEtaPanel(
          progress: _progress,
          riderPickupName: _trip?.passengerPickupName ?? _pickupName,
          riderBoarded: _trip?.passengerBoarded ?? false,
          fallbackArrival: _trip?.arrivalAt,
        ),
        const SizedBox(height: 16),
        // Smart per-stop progress with live ETAs
        TrackingStopsTimeline(
          progress: _progress,
          riderPickupName: _trip?.passengerPickupName ?? _pickupName,
          riderBoarded: _trip?.passengerBoarded ?? false,
        ),
        const SizedBox(height: 16),
        // Latest driver-sent location metrics.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                Icons.speed_rounded,
                'Speed',
                _trip?.vehicleSpeedKmh == null
                    ? 'Pending'
                    : '${_trip!.vehicleSpeedKmh!.round()} km/h',
                ClientColors.primary,
              ),
              _buildMetricItem(
                Icons.location_on_rounded,
                'GPS',
                _trip?.hasLiveVehicleLocation == true ? 'Received' : 'Waiting',
                ClientColors.journeyGreen,
              ),
              _buildMetricItem(
                Icons.update_rounded,
                'Updated',
                _liveLocationLabel(),
                scheme.tertiary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STATE 5: Trip completed UI
  Widget _buildCompletedView(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.green.withAlpha(70)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You Have Arrived!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Thank you for riding with Mega Transportation.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20),
              _buildSummaryRow('Route', _routeName),
              _buildSummaryRow('Pickup', _pickupName),
              _buildSummaryRow('Destination', _destinationName),
              _buildSummaryRow('Arrival Time', _formatTime(_trip?.arrivalAt)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Rating Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate Your Ride Experience',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInteractiveRatingRow(
                'Rate Captain',
                _driverRating,
                context.read<TrackingCubit>().rateDriver,
                scheme,
              ),
              const SizedBox(height: 10),
              _buildInteractiveRatingRow(
                'Rate Shuttle Vehicle',
                _vehicleRating,
                context.read<TrackingCubit>().rateVehicle,
                scheme,
              ),
              const SizedBox(height: 10),
              _buildInteractiveRatingRow(
                'Rate Route & Smoothness',
                _routeRating,
                context.read<TrackingCubit>().rateRoute,
                scheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ClientButton(
          label: 'Book Another Trip',
          expand: true,
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
      ],
    );
  }

  // --- REUSABLE CARD COMPONENTS ---

  // Interactive Rate Row
  Widget _buildInteractiveRatingRow(
    String label,
    int currentRating,
    Function(int) onRatingChanged,
    ColorScheme scheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= currentRating;
            return GestureDetector(
              onTap: () => onRatingChanged(starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFilled
                      ? scheme.tertiary
                      : Colors.grey.withAlpha(150),
                  size: 20,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Summary Row helper
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Driver Card with Actions for Active screen
  Widget _buildDriverActionCard(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ClientColors.primaryLight,
                child: Text(
                  _trip?.driverInitials ?? 'DR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ClientColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _trip?.displayDriverName ?? 'Driver assigned',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.textPrimaryFor(context),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: scheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _trip?.driverRating?.toStringAsFixed(1) ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: ClientButton.secondary(
                  label: 'Call Driver',
                  expand: true,
                  onPressed: () =>
                      _showContactInfo(context, 'Driver', _trip?.driverPhone),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClientButton(
                  label: 'Chat Driver',
                  expand: true,
                  onPressed: () => Navigator.of(context).pushNamed('/support'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // --- GENERAL WIDGETS ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(120),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  void _showContactInfo(BuildContext context, String title, String? phone) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ClientColors.surfaceFor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                phone == null || phone.trim().isEmpty
                    ? 'Driver phone is not available for this trip yet.'
                    : 'Phone: $phone',
                style: TextStyle(
                  fontSize: 13,
                  color: ClientColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: ClientColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- BACKGOUND GLOW DECORATIVE PAINTER ---
class _BackgroundGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _BackgroundGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}

